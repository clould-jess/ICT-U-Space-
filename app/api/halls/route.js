import prisma from '../../../lib/prisma';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Cookie',
};

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function GET() {
  try {
    const halls = await prisma.hall.findMany({ orderBy: { name: 'asc' } });
    return new Response(JSON.stringify(halls), { status: 200, headers: corsHeaders });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Failed to fetch halls' }), { status: 500, headers: corsHeaders });
  }
}
