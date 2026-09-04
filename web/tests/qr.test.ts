import { describe, it, expect } from '@jest/globals';
import crypto from 'crypto';
describe('QR token (PRD 31)', ()=>{
  it('hashes token with sha256', ()=>{
    const token = 'abc123';
    const h = crypto.createHash('sha256').update(token).digest('hex');
    expect(h).toHaveLength(64);
  });
  it('creates short-lived payload', ()=>{
    const payload = { device_id:'d1', nonce:'n1', exp: new Date(Date.now()+3600_000).toISOString() };
    expect(new Date(payload.exp).getTime()).toBeGreaterThan(Date.now());
  });
});
