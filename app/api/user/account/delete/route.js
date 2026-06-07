import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../../lib/auth';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function DELETE(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    if (session.role === 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Admin accounts cannot be deleted' }), { status: 403, headers: corsHeaders });
    }

    const { password } = await request.json();
    if (!password) {
      return new Response(JSON.stringify({ error: 'Password is required to delete account' }), { status: 400, headers: corsHeaders });
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

    await prisma.user.delete({ where: { id: session.id } });
    return new Response(JSON.stringify({ success: true }), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('Delete account error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: corsHeaders });
  }
}
