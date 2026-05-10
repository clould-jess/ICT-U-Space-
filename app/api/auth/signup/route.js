import prisma from '../../../../lib/prisma';
import { cookies } from 'next/headers';

export async function POST(request) {
  try {
    const { name, email, password } = await request.json();

    if (!name || !email || !password) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), { status: 400 });
    }

    if (!email.toLowerCase().endsWith('@ictuniversity.edu.cm')) {
      return new Response(JSON.stringify({ error: 'Registration is restricted to @ictuniversity.edu.cm emails only.' }), { status: 403 });
    }

    const existingUser = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });

    if (existingUser) {
      return new Response(JSON.stringify({ error: 'Email already registered' }), { status: 409 });
    }

    const newUser = await prisma.user.create({
      data: { name, email: email.toLowerCase(), password, role: 'STUDENT' }
    });

    const sessionData = { id: newUser.id, name: newUser.name, role: newUser.role, email: newUser.email };

    (await cookies()).set('session', JSON.stringify(sessionData), {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      maxAge: 60 * 60 * 24 * 7,
      path: '/',
    });

    return new Response(JSON.stringify({ success: true, user: sessionData }), { status: 201 });
  } catch (error) {
    console.error('Signup error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 });
  }
}
