import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function POST(request) {
  try {
    const { email } = await request.json();
    
    if (!email) {
      return new Response(JSON.stringify({ error: 'Missing email' }), { status: 400 });
    }

    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() }
    });

    if (!user) {
      // Even if user doesn't exist, we return success to prevent email enumeration
      return new Response(JSON.stringify({ success: true, message: 'If an account exists, a reset link will be sent.' }), { status: 200 });
    }

    // In a real app, send an email here.
    // For this prototype, we just return success.
    return new Response(JSON.stringify({ success: true, message: 'Password reset link sent.' }), { status: 200 });
  } catch (error) {
    console.error('Forgot password error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 });
  }
}
