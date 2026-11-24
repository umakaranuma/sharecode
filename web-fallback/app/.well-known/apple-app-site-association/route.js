export async function GET() {
  const teamId = process.env.IOS_TEAM_ID;
  const bundleId = process.env.IOS_BUNDLE_ID;
  if (!teamId || !bundleId) return new Response('Not configured', { status: 404 });
  return Response.json({ applinks: { apps: [], details: [{ appID: `${teamId}.${bundleId}`, paths: ['/u/*'] }] } });
}
