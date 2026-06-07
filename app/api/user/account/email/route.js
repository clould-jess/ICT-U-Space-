import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../../lib/auth';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function POST(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const { newEmail, password } = await request.json();
    if (!newEmail || !password) {
      return new Response(JSON.stringify({ error: 'New email and password are required' }), { status: 400, headers: corsHeaders });
    }

    const user = await prisma.user.findUnique({ where: { id: session.id } });
    
    let isPasswordValid = false;
    if (user && (user.password.startsWith('$2a$') || user.password.startsWith('$2b$'))) {
      isPasswordValid = await bcrypt.compare(password, user.password);
    } else if (user) {
      isPasswordValid = password === user.password;
    }

    if (!user || !isPasswordValid) {
      return new Response(JSON.stringify({ error: 'Incorrect password' }), { status: 401, headers: corsHeaders });
    }

    const normalized = newEmail.toLowerCase().trim();
    const existing = await prisma.user.findUnique({ where: { email: normalized } });
    if (existing && existing.id !== session.id) {
      return new Response(JSON.stringify({ error: 'Email already in use by another account' }), { status: 409, headers: corsHeaders });
    }

    const updated = await prisma.user.update({ where: { id: session.id }, data: { email: normalized } });
    return new Response(JSON.stringify({ success: true, email: updated.email }), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('Change email error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: corsHeaders });
  }
}
