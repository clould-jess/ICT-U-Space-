import { PrismaClient } from '@prisma/client';
import { cookies } from 'next/headers';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Cookie, x-session',
};

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function POST(request) {
  try {
    const { email, password } = await request.json();

    if (!email || !password) {
      return new Response(
        JSON.stringify({ error: 'Missing credentials' }),
        { status: 400, headers: corsHeaders }
      );
    }

    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    let isPasswordValid = false;
    
    // For backwards compatibility with the original seed users (plaintext passwords)
    // we check if the stored password starts with the bcrypt signature. 
    // If it's the seed 'naruto', we'll allow it and maybe it should be hashed, 
    // but for now let's just do a dual check.
    if (user && (user.password.startsWith('$2a$') || user.password.startsWith('$2b$'))) {
      isPasswordValid = await bcrypt.compare(password, user.password);
    } else if (user) {
      isPasswordValid = password === user.password;
    }

    if (!user || !isPasswordValid) {
      return new Response(
        JSON.stringify({ error: 'Invalid email or password' }),
        { status: 401, headers: corsHeaders }
      );
    }

    const sessionData = {
      id: user.id,
      name: user.name,
      role: user.role,
      email: user.email,
      matricule: user.matricule ?? null,
      academic_level: user.academic_level ?? null,
      semester: user.semester ?? null,
    };

    (await cookies()).set('session', JSON.stringify(sessionData), {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      maxAge: 60 * 60 * 24 * 7,
      path: '/',
    });

    return new Response(
      JSON.stringify({ success: true, user: sessionData }),
      { status: 200, headers: corsHeaders }
    );
  } catch (error) {
    console.error('Login error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: corsHeaders }
    );
  }
}
