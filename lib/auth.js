import { cookies } from 'next/headers';

/**
 * Read the session from either the httpOnly cookie (browser) or the
 * x-session request header (Flutter / mobile clients).
 *
 * Returns the parsed session object, or null if not authenticated.
 */
export async function getSession(request) {
  // 1. Try the httpOnly cookie set by the login route (works for same-origin
  //    browser requests where the browser sends cookies automatically).
  try {
    const cookieStore = await cookies();
    const sessionCookie = cookieStore.get('session');
    if (sessionCookie?.value) {
      return JSON.parse(sessionCookie.value);
    }
  } catch (_) {}

  // 2. Fall back to the x-session header (sent by the Flutter app which
  //    cannot rely on httpOnly cookies across origins).
  const xSession = request?.headers?.get('x-session');
  if (xSession) {
    try {
      return JSON.parse(decodeURIComponent(xSession));
    } catch (_) {}
  }

  return null;
}

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Cookie, x-session',
};
