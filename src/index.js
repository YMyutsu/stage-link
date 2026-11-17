export default {
  async fetch(request, env) {
    if (new URL(request.url).pathname !== '/api/messages') {
      return new Response('Not Found', { status: 404 });
    }

    if (request.method === 'GET') {
      const { results } = await env.DB.prepare(
        'SELECT * FROM messages ORDER BY id DESC LIMIT 100'
      ).all();
      return Response.json(results, {
        status: 200,
        headers: { 'Cache-Control': 'no-store' }
      });
    }

if (request.method === 'POST') {
  const m = await request.json();
  await env.DB.prepare(
    'INSERT INTO messages (name, emoji, text) VALUES (?, ?, ?)'
  ).bind(m.name, m.emoji, m.text).run();

  return Response.json({ ok: true }, { status: 201 });
}
}
};