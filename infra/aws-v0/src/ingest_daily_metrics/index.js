const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const { DynamoDBDocumentClient, UpdateCommand, GetCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const secretsClient = new SecretsManagerClient({});

const USERS_TABLE = process.env.USERS_TABLE;
const DAILY_TABLE = process.env.DAILY_TABLE;
const SECRET_ID = process.env.SECRET_ID;

let cachedApiKey = null;
let cachedAt = 0;
const CACHE_TTL_MS = 5 * 60 * 1000;

function jsonResponse(statusCode, body) {
  return {
    statusCode,
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  };
}

function parseBody(event) {
  if (!event || !event.body) return { ok: false, error: "missing_body" };
  try {
    const raw = event.isBase64Encoded
      ? Buffer.from(event.body, "base64").toString("utf8")
      : event.body;
    return { ok: true, value: JSON.parse(raw) };
  } catch (err) {
    return { ok: false, error: "invalid_json" };
  }
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function clampNumber(value, max) {
  if (value < 0) return 0;
  if (value > max) return max;
  return value;
}

const METRIC_KEYS = [
  "social_minutes",
  "video_game_minutes",
  "streaming_minutes",
  "shopping_minutes",
  "news_minutes",
  "sports_minutes",
  "goals_completed",
  "shield_hits",
  "session_count",
  "session_total_minutes",
];

function normalizeProfile(profile, details) {
  if (profile === undefined || profile === null) return null;
  if (!isPlainObject(profile)) {
    details.push("profile must be an object");
    return null;
  }
  const displayName = profile.display_name;
  if (typeof displayName !== "string" || displayName.length < 1 || displayName.length > 64) {
    details.push("profile.display_name must be a string (1..64 chars)");
  }
  const birthMonth = profile.birth_month;
  if (!Number.isInteger(birthMonth) || birthMonth < 1 || birthMonth > 12) {
    details.push("profile.birth_month must be an integer 1..12");
  }
  const birthDay = profile.birth_day;
  if (!Number.isInteger(birthDay) || birthDay < 1 || birthDay > 31) {
    details.push("profile.birth_day must be an integer 1..31");
  }
  return {
    display_name: displayName,
    birth_month: birthMonth,
    birth_day: birthDay,
  };
}

function validateAndNormalize(body) {
  const details = [];

  if (!isPlainObject(body)) {
    return { ok: false, details: ["body must be an object"] };
  }

  const userId = body.user_id;
  if (typeof userId !== "string" || userId.length < 1 || userId.length > 128) {
    details.push("user_id must be a string (1..128 chars)");
  }

  const timezone = body.timezone;
  if (typeof timezone !== "string" || timezone.length < 1 || timezone.length > 64) {
    details.push("timezone must be a string (1..64 chars)");
  }

  const profile = normalizeProfile(body.profile, details);

  const isBatch = Array.isArray(body.items);
  if (isBatch) {
    if (body.items.length === 0) {
      details.push("items must be non-empty");
    }
  } else {
    if (typeof body.date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(body.date)) {
      details.push("date must be YYYY-MM-DD");
    }
    if (!isPlainObject(body.metrics)) {
      details.push("metrics must be an object");
    }
  }

  if (details.length > 0) {
    return { ok: false, details };
  }

  const normalizeMetrics = (metrics) => {
    const out = {};
    const normalizedMetrics = isPlainObject(metrics) ? { ...metrics } : {};
    if (normalizedMetrics.shield_hits === undefined && normalizedMetrics.shield_opens !== undefined) {
      normalizedMetrics.shield_hits = normalizedMetrics.shield_opens;
    }
    for (const key of METRIC_KEYS) {
      const value = normalizedMetrics ? normalizedMetrics[key] : undefined;
      if (value === undefined || value === null) {
        out[key] = 0;
        continue;
      }
      if (typeof value !== "number" || Number.isNaN(value)) {
        details.push(`metrics.${key} must be a number`);
        continue;
      }
      const isMinutes = key.includes("minutes");
      const max = isMinutes ? 1440 : 1000;
      out[key] = clampNumber(value, max);
    }
    return out;
  };

  if (isBatch) {
    const items = [];
    for (const item of body.items) {
      if (!isPlainObject(item)) {
        details.push("each item must be an object");
        continue;
      }
      if (typeof item.date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(item.date)) {
        details.push("each item date must be YYYY-MM-DD");
      }
      const resetMinutes =
        Number.isInteger(item.daily_reset_session_start_time) ? item.daily_reset_session_start_time : item.reset_time_minutes;
      if (!Number.isInteger(resetMinutes) || resetMinutes < 0 || resetMinutes > 1439) {
        details.push("each item daily_reset_session_start_time must be 0..1439");
      }
      if (item.daily_session_start_time !== undefined &&
          (typeof item.daily_session_start_time !== "string" ||
           !/^([01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d$/.test(item.daily_session_start_time))) {
        details.push("each item daily_session_start_time must be HH:MM:SS");
      }
      if (!isPlainObject(item.metrics)) {
        details.push("each item metrics must be an object");
      }
      const normalized = {
        date: item.date,
        daily_reset_session_start_time: resetMinutes,
        daily_session_start_time: item.daily_session_start_time,
        metrics: normalizeMetrics(item.metrics),
      };
      items.push(normalized);
    }
    if (details.length > 0) {
      return { ok: false, details };
    }
    return {
      ok: true,
      user_id: userId,
      timezone,
      profile,
      items,
    };
  }

  const resetMinutes =
    Number.isInteger(body.daily_reset_session_start_time) ? body.daily_reset_session_start_time : body.reset_time_minutes;
  if (!Number.isInteger(resetMinutes) || resetMinutes < 0 || resetMinutes > 1439) {
    details.push("daily_reset_session_start_time must be an integer 0..1439");
  }
  if (body.daily_session_start_time !== undefined &&
      (typeof body.daily_session_start_time !== "string" ||
       !/^([01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d$/.test(body.daily_session_start_time))) {
    details.push("daily_session_start_time must be HH:MM:SS");
  }

  const normalized = {
    user_id: userId,
    date: body.date,
    timezone,
    daily_reset_session_start_time: resetMinutes,
    daily_session_start_time: body.daily_session_start_time,
    metrics: normalizeMetrics(body.metrics),
    profile,
  };

  if (details.length > 0) {
    return { ok: false, details };
  }

  return { ok: true, item: normalized };
}

function getHeader(event, name) {
  if (!event || !event.headers) return null;
  const headers = event.headers;
  const lowerName = name.toLowerCase();
  for (const [key, value] of Object.entries(headers)) {
    if (key.toLowerCase() === lowerName) return value;
  }
  return null;
}

function timingSafeEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i += 1) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

async function getExpectedApiKey() {
  const now = Date.now();
  if (cachedApiKey && now - cachedAt < CACHE_TTL_MS) {
    return cachedApiKey;
  }
  if (!SECRET_ID) return null;
  const resp = await secretsClient.send(
    new GetSecretValueCommand({ SecretId: SECRET_ID })
  );
  const raw = resp.SecretString || "{}";
  const data = JSON.parse(raw);
  cachedApiKey = data.ingest_api_key || null;
  cachedAt = now;
  return cachedApiKey;
}

async function getUser(userId) {
  const cmd = new GetCommand({
    TableName: USERS_TABLE,
    Key: { user_id: userId },
  });
  const resp = await docClient.send(cmd);
  return resp.Item || null;
}

async function upsertUser(userId, timezone, profile) {
  const now = new Date().toISOString();
  let updateExpression =
    "SET #tz = if_not_exists(#tz, :tz), created_at = if_not_exists(created_at, :now), last_active_at = :now";
  const expressionAttributeNames = { "#tz": "timezone" };
  const expressionAttributeValues = {
    ":tz": timezone || "UTC",
    ":now": now,
  };

  if (profile) {
    updateExpression +=
      ", display_name = if_not_exists(display_name, :dn), birth_month = if_not_exists(birth_month, :bm), birth_day = if_not_exists(birth_day, :bd)";
    expressionAttributeValues[":dn"] = profile.display_name;
    expressionAttributeValues[":bm"] = profile.birth_month;
    expressionAttributeValues[":bd"] = profile.birth_day;
  }

  const cmd = new UpdateCommand({
    TableName: USERS_TABLE,
    Key: { user_id: userId },
    UpdateExpression: updateExpression,
    ExpressionAttributeNames: expressionAttributeNames,
    ExpressionAttributeValues: expressionAttributeValues,
  });
  await docClient.send(cmd);
}

async function upsertDaily(userId, item) {
  const now = new Date().toISOString();
  const metrics = item.metrics || {};
  let updateExpression =
    "SET #tz = :tz, daily_reset_session_start_time = :rtm, " +
    "social_minutes = :social, video_game_minutes = :games, streaming_minutes = :stream, " +
    "shopping_minutes = :shopping, news_minutes = :news, sports_minutes = :sports, " +
    "goals_completed = :goals, shield_hits = :shield, session_count = :sessions, " +
    "session_total_minutes = :sessionMinutes, " +
    "created_at = if_not_exists(created_at, :createdAt), updated_at = :updatedAt";
  if (item.daily_session_start_time) {
    updateExpression += ", daily_session_start_time = :sessionStart";
  }

  const cmd = new UpdateCommand({
    TableName: DAILY_TABLE,
    Key: { user_id: userId, date: item.date },
    UpdateExpression: updateExpression,
    ExpressionAttributeNames: {
      "#tz": "timezone",
    },
    ExpressionAttributeValues: {
      ":tz": item.timezone || "UTC",
      ":rtm": item.daily_reset_session_start_time ?? 0,
      ":social": metrics.social_minutes ?? 0,
      ":games": metrics.video_game_minutes ?? 0,
      ":stream": metrics.streaming_minutes ?? 0,
      ":shopping": metrics.shopping_minutes ?? 0,
      ":news": metrics.news_minutes ?? 0,
      ":sports": metrics.sports_minutes ?? 0,
      ":goals": metrics.goals_completed ?? 0,
      ":shield": metrics.shield_hits ?? 0,
      ":sessions": metrics.session_count ?? 0,
      ":sessionMinutes": metrics.session_total_minutes ?? 0,
      ":createdAt": now,
      ":updatedAt": now,
      ...(item.daily_session_start_time ? { ":sessionStart": item.daily_session_start_time } : {}),
    },
  });
  await docClient.send(cmd);
}

exports.handler = async (event) => {
  try {
    const providedKey = getHeader(event, "x-anchor-api-key");
    const expectedKey = await getExpectedApiKey();
    if (!expectedKey) {
      return jsonResponse(500, { ok: false, error: "server_not_configured" });
    }
    if (!providedKey || !timingSafeEqual(providedKey, expectedKey)) {
      return jsonResponse(401, { ok: false, error: "unauthorized" });
    }

    const parsed = parseBody(event);
    if (!parsed.ok) {
      return jsonResponse(400, {
        ok: false,
        error: "bad_request",
        details: [parsed.error],
      });
    }
    const validation = validateAndNormalize(parsed.value);
    if (!validation.ok) {
      return jsonResponse(400, {
        ok: false,
        error: "bad_request",
        details: validation.details,
      });
    }

    const userId = validation.items ? validation.user_id : validation.item.user_id;
    const timezone = validation.items ? validation.timezone : validation.item.timezone;

    if (!userId) {
      console.error("ingest_error missing_user_id_after_validation");
      return jsonResponse(500, { ok: false, error: "internal_error" });
    }

    const profile = validation.items ? validation.profile : validation.item.profile;
    const existingUser = await getUser(userId);
    const missingProfileFields =
      !existingUser ||
      !existingUser.display_name ||
      !existingUser.birth_month ||
      !existingUser.birth_day;
    if (missingProfileFields && !profile) {
      return jsonResponse(400, {
        ok: false,
        error: "bad_request",
        details: ["profile is required for new users or users missing profile fields"],
      });
    }

    await upsertUser(userId, timezone, profile);

    if (validation.items) {
      for (const item of validation.items) {
        await upsertDaily(userId, { ...item, timezone });
      }
    } else if (validation.item) {
      await upsertDaily(userId, validation.item);
    }

    return jsonResponse(200, { ok: true });
  } catch (err) {
    console.error("ingest_error", err?.message || err, err?.stack || null);
    return jsonResponse(500, { ok: false, error: "internal_error" });
  }
};
