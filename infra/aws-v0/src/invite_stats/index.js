export const handler = async (event) => {
  const qs = event.queryStringParameters || {};
  const inviterId = qs.inviterId || null;
  const inviteCode = qs.inviteCode || null;

  if (!inviterId || !inviteCode) {
    return { statusCode: 400, body: JSON.stringify({ error: "Missing inviterId or inviteCode" }) };
  }

  // TODO: Replace with DynamoDB lookup keyed by inviterId+inviteCode
  // For now return 0 so app wiring can ship.
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ inviteCount: 0 })
  };
};
