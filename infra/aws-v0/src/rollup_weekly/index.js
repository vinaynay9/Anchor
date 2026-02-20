const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, ScanCommand, QueryCommand, PutCommand, UpdateCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const USERS_TABLE = process.env.USERS_TABLE;
const DAILY_TABLE = process.env.DAILY_TABLE;
const WEEKLY_TABLE = process.env.WEEKLY_TABLE;
const GLOBAL_TABLE = process.env.GLOBAL_TABLE;

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

const WEEKLY_TOTAL_KEYS = {
  social_minutes: "total_social_minutes",
  video_game_minutes: "total_video_game_minutes",
  streaming_minutes: "total_streaming_minutes",
  shopping_minutes: "total_shopping_minutes",
  news_minutes: "total_news_minutes",
  sports_minutes: "total_sports_minutes",
  goals_completed: "total_goals_completed",
  shield_hits: "total_shield_hits",
  session_count: "total_sessions",
  session_total_minutes: "total_session_minutes",
};

function startOfWeekUtcMonday(date = new Date()) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = d.getUTCDay(); // 0=Sun
  const diff = (day + 6) % 7; // Monday start
  d.setUTCDate(d.getUTCDate() - diff);
  return d;
}

function formatDate(d) {
  return d.toISOString().slice(0, 10);
}

function addDays(d, days) {
  const out = new Date(d);
  out.setUTCDate(out.getUTCDate() + days);
  return out;
}

function sumMetrics(items) {
  const totals = {};
  for (const key of METRIC_KEYS) {
    totals[key] = 0;
  }
  for (const item of items) {
    for (const key of METRIC_KEYS) {
      let n = typeof item[key] === "number" ? item[key] : 0;
      if (key === "shield_hits" && n === 0 && typeof item.shield_opens === "number") {
        n = item.shield_opens;
      }
      totals[key] += n;
    }
  }
  return totals;
}

function toWeeklyTotals(totals) {
  const weekly = {};
  for (const [key, weeklyKey] of Object.entries(WEEKLY_TOTAL_KEYS)) {
    weekly[weeklyKey] = totals[key] || 0;
  }
  return weekly;
}

function jsonResponse(statusCode, body) {
  return {
    statusCode,
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  };
}

exports.handler = async (event = {}) => {
  const overrideWeekStart = typeof event.week_start === "string" ? event.week_start : null;
  const overrideUserId = typeof event.user_id === "string" ? event.user_id : null;
  if (overrideWeekStart) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(overrideWeekStart)) {
      return jsonResponse(400, {
        ok: false,
        error: "bad_request",
        details: ["week_start must be YYYY-MM-DD"],
      });
    }
  }
  const baseDate = overrideWeekStart ? new Date(`${overrideWeekStart}T00:00:00Z`) : new Date();
  const weekStart = startOfWeekUtcMonday(baseDate);
  if (overrideWeekStart && formatDate(weekStart) !== overrideWeekStart) {
    return jsonResponse(400, {
      ok: false,
      error: "bad_request",
      details: ["week_start must be a Monday (UTC)"],
    });
  }
  const weekStartStr = formatDate(weekStart);
  const weekEndStr = formatDate(addDays(weekStart, 6));

  let users = [];
  if (overrideUserId) {
    users = [{ user_id: overrideUserId }];
  } else {
    let lastKey = undefined;
    do {
      const scan = new ScanCommand({
        TableName: USERS_TABLE,
        ExclusiveStartKey: lastKey,
        ProjectionExpression: "user_id",
      });
      const resp = await docClient.send(scan);
      users = users.concat(resp.Items || []);
      lastKey = resp.LastEvaluatedKey;
    } while (lastKey);
  }

  let globalTotals = {};
  for (const key of METRIC_KEYS) {
    globalTotals[key] = 0;
  }
  let activeUsers = 0;

  for (const user of users) {
    const userId = user.user_id;
    if (!userId) continue;

    const query = new QueryCommand({
      TableName: DAILY_TABLE,
      KeyConditionExpression: "user_id = :uid AND #d BETWEEN :start AND :end",
      ExpressionAttributeNames: { "#d": "date" },
      ExpressionAttributeValues: {
        ":uid": userId,
        ":start": weekStartStr,
        ":end": weekEndStr,
      },
    });
    const resp = await docClient.send(query);
    const items = resp.Items || [];
    const totals = sumMetrics(items);
    const weeklyTotals = toWeeklyTotals(totals);
    if (items.length > 0) {
      activeUsers += 1;
    }

    for (const key of METRIC_KEYS) {
      globalTotals[key] += totals[key] || 0;
    }

    const totalSessions = weeklyTotals.total_sessions || 0;
    const goalCompletionRate =
      (weeklyTotals.total_goals_completed || 0) / Math.max(1, totalSessions);

    await docClient.send(
      new UpdateCommand({
        TableName: WEEKLY_TABLE,
        Key: { user_id: userId, week_start: weekStartStr },
        UpdateExpression:
          "SET total_social_minutes = :social, total_video_game_minutes = :games, total_streaming_minutes = :stream, " +
          "total_shopping_minutes = :shopping, total_news_minutes = :news, total_sports_minutes = :sports, " +
          "total_goals_completed = :goals, total_shield_hits = :shield, total_sessions = :sessions, " +
          "total_session_minutes = :sessionMinutes, goal_completion_rate = :gcr, " +
          "created_at = if_not_exists(created_at, :createdAt), updated_at = :updatedAt",
        ExpressionAttributeValues: {
          ":social": weeklyTotals.total_social_minutes || 0,
          ":games": weeklyTotals.total_video_game_minutes || 0,
          ":stream": weeklyTotals.total_streaming_minutes || 0,
          ":shopping": weeklyTotals.total_shopping_minutes || 0,
          ":news": weeklyTotals.total_news_minutes || 0,
          ":sports": weeklyTotals.total_sports_minutes || 0,
          ":goals": weeklyTotals.total_goals_completed || 0,
          ":shield": weeklyTotals.total_shield_hits || 0,
          ":sessions": weeklyTotals.total_sessions || 0,
          ":sessionMinutes": weeklyTotals.total_session_minutes || 0,
          ":gcr": goalCompletionRate,
          ":createdAt": new Date().toISOString(),
          ":updatedAt": new Date().toISOString(),
        },
      })
    );

    await docClient.send(
      new UpdateCommand({
        TableName: USERS_TABLE,
        Key: { user_id: userId },
        UpdateExpression:
          "SET lifetime_goals_completed = if_not_exists(lifetime_goals_completed, :zero) + :goals, " +
          "lifetime_social_minutes = if_not_exists(lifetime_social_minutes, :zero) + :social, " +
          "lifetime_sessions = if_not_exists(lifetime_sessions, :zero) + :sessions, " +
          "lifetime_shield_hits = if_not_exists(lifetime_shield_hits, :zero) + :shieldHits",
        ExpressionAttributeValues: {
          ":zero": 0,
          ":goals": weeklyTotals.total_goals_completed || 0,
          ":social": weeklyTotals.total_social_minutes || 0,
          ":sessions": weeklyTotals.total_sessions || 0,
          ":shieldHits": weeklyTotals.total_shield_hits || 0,
        },
      })
    );
  }

  const globalItems = [
    { metric_name: "active_users", period: weekStartStr, value: activeUsers },
    {
      metric_name: "total_goals_completed",
      period: weekStartStr,
      value: globalTotals.goals_completed || 0,
    },
    {
      metric_name: "total_social_minutes",
      period: weekStartStr,
      value: globalTotals.social_minutes || 0,
    },
  ];

  for (const item of globalItems) {
    await docClient.send(
      new PutCommand({
        TableName: GLOBAL_TABLE,
        Item: {
          ...item,
          updated_at: new Date().toISOString(),
        },
      })
    );
  }

  return { ok: true, week_start: weekStartStr };
};
