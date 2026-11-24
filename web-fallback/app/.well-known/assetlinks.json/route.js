export async function GET() {
  const packageName = process.env.ANDROID_APP_ID;
  const fingerprint = process.env.ANDROID_SHA256_FINGERPRINT;
  if (!packageName || !fingerprint) return new Response('Not configured', { status: 404 });
  return Response.json([{ relation: ['delegate_permission/common.handle_all_urls'], target: { namespace: 'android_app', package_name: packageName, sha256_cert_fingerprints: [fingerprint] } }]);
}
