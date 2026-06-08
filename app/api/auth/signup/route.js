import prisma from '../../../../lib/prisma';
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

/**
 * Detect role from matricule prefix.
 * ICTULEC... → LECTURER
 * ICTU...    → STUDENT
 */
function detectRoleFromMatricule(matricule) {
  const upper = matricule.trim().toUpperCase();
  if (upper.startsWith('ICTULEC')) return 'LECTURER';
  if (upper.startsWith('ICTU')) return 'STUDENT';
  return null; // invalid
}

export async function POST(request) {
  try {
    const { name, email, password, matricule } = await request.json();

    if (!name || !email || !password) {
      return new Response(
        JSON.stringify({ error: 'Name, email, and password are required.' }),
        { status: 400, headers: corsHeaders }
      );
    }

    if (!matricule) {
      return new Response(
        JSON.stringify({ error: 'Matricule number is required.' }),
        { status: 400, headers: corsHeaders }
      );
    }

    if (!email.toLowerCase().endsWith('@ictuniversity.edu.cm')) {
      return new Response(
        JSON.stringify({ error: 'Registration is restricted to @ictuniversity.edu.cm emails only.' }),
        { status: 403, headers: corsHeaders }
      );
    }

    const normalizedMatricule = matricule.trim().toUpperCase();
    const role = detectRoleFromMatricule(normalizedMatricule);

    if (!role) {
      return new Response(
        JSON.stringify({
          error: 'Invalid matricule. Lecturer matricules start with ICTULEC, student matricules start with ICTU.',
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Check if email is already registered
    const existingEmail = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });
    if (existingEmail) {
      return new Response(
        JSON.stringify({ error: 'This email is already registered.' }),
        { status: 409, headers: corsHeaders }
      );
    }

    // Check if matricule is already registered
    const existingMatricule = await prisma.user.findUnique({
      where: { matricule: normalizedMatricule },
    });
    if (existingMatricule) {
      return new Response(
        JSON.stringify({ error: 'This matricule number is already registered.' }),
        { status: 409, headers: corsHeaders }
      );
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await prisma.user.create({
      data: {
        name,
        email: email.toLowerCase(),
        password: hashedPassword,
        role,
        matricule: normalizedMatricule,
      },
    });

    const sessionData = {
      id: newUser.id,
      name: newUser.name,
      role: newUser.role,
      email: newUser.email,
      matricule: newUser.matricule,
    };

    (await cookies()).set('session', JSON.stringify(sessionData), {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      maxAge: 60 * 60 * 24 * 7,
      path: '/',
    });

    return new Response(
      JSON.stringify({ success: true, user: sessionData }),
      { status: 201, headers: corsHeaders }
    );
  } catch (error) {
    console.error('Signup error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: corsHeaders }
    );
  }
}
