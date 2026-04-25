import { cookies } from 'next/headers';

export async function POST() {
  (await cookies()).delete('session');
  return new Response(JSON.stringify({ success: true }), { status: 200 });
}
