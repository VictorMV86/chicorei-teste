const request = require('supertest');
const app = require('../src/index');

describe('GET /', () => {
  it('deve retornar "Olá Chico Rei!"', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.text).toBe('Olá Chico Rei!');
  });
});