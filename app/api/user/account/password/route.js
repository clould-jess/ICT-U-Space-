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

    const { currentPassword, newPassword } = await request.json();
    if (!currentPassword || !newPassword) {
      return new Response(JSON.stringify({ error: 'Both current and new password are required' }), { status: 400, headers: corsHeaders });
    }
    if (newPassword.length < 6) {
      return new Response(JSON.stringify({ error: 'New password must be at least 6 characters' }), { status: 400, headers: corsHeaders });
    }

    const user = await prisma.user.findUnique({ where: { id: session.id } });
    let isPasswordValid = false;
    if (user && (user.password.startsWith('$2a$') || user.password.startsWith('$2b$'))) {
      isPasswordValid = await bcrypt.compare(currentPassword, user.password);
    } else if (user) {
      isPasswordValid = currentPassword === user.password;
    }

    if (!user || !isPasswordValid) {
      return new Response(JSON.stringify({ error: 'Current password is incorrect' }), { status: 401, headers: corsHeaders });
    }

    const hashedNewPassword = await bcrypt.hash(newPassword, 10);
    await prisma.user.update({ where: { id: session.id }, data: { password: hashedNewPassword } });
    return new Response(JSON.stringify({ success: true }), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('Change password error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: corsHeaders });
  }
}
