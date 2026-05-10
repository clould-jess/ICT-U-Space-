import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';

export async function POST(request) {
  (await cookies()).delete('session');
  return NextResponse.redirect(new URL('/login', request.url), { status: 303 });
}
