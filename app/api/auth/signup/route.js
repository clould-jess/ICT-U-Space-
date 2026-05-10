<<<<<<< HEAD
import prisma from '../../../../lib/prisma';
import { cookies } from 'next/headers';

export async function POST(request) {
  try {
    const { name, email, password } = await request.json();

=======
import { PrismaClient } from '@prisma/client';
import { cookies } from 'next/headers';

const prisma = new PrismaClient();

export async function POST(request) {
  try {
    const { name, email, password } = await request.json();
    
>>>>>>> 1229ad69d61cc025bf7943a328efa21b2faae813
    if (!name || !email || !password) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), { status: 400 });
    }

<<<<<<< HEAD
=======
    // Enforce email domain restriction
>>>>>>> 1229ad69d61cc025bf7943a328efa21b2faae813
    if (!email.toLowerCase().endsWith('@ictuniversity.edu.cm')) {
      return new Response(JSON.stringify({ error: 'Registration is restricted to @ictuniversity.edu.cm emails only.' }), { status: 403 });
    }

<<<<<<< HEAD
    const existingUser = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });
=======
    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: email.toLowerCase() }
    });
>>>>>>> 1229ad69d61cc025bf7943a328efa21b2faae813

    if (existingUser) {
      return new Response(JSON.stringify({ error: 'Email already registered' }), { status: 409 });
    }

<<<<<<< HEAD
    const newUser = await prisma.user.create({
      data: { name, email: email.toLowerCase(), password, role: 'STUDENT' }
    });

    const sessionData = { id: newUser.id, name: newUser.name, role: newUser.role, email: newUser.email };

    (await cookies()).set('session', JSON.stringify(sessionData), {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      maxAge: 60 * 60 * 24 * 7,
=======
    // Create the new user with default STUDENT role
    const newUser = await prisma.user.create({
      data: {
        name,
        email: email.toLowerCase(),
        password, // Storing plaintext as requested for prototype compatibility
        role: 'STUDENT'
      }
    });

    // Set simple session cookie to auto-login
    const sessionData = {
      id: newUser.id,
      name: newUser.name,
      role: newUser.role,
      email: newUser.email
    };
    
    (await cookies()).set('session', JSON.stringify(sessionData), {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      maxAge: 60 * 60 * 24 * 7, // 1 week
>>>>>>> 1229ad69d61cc025bf7943a328efa21b2faae813
      path: '/',
    });

    return new Response(JSON.stringify({ success: true, user: sessionData }), { status: 201 });
  } catch (error) {
    console.error('Signup error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 });
  }
}
