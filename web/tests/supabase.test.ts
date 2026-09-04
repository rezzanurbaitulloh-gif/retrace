import { describe, it, expect } from '@jest/globals';
describe('Supabase RLS placeholders', ()=>{
  it('defines device states', ()=>{
    const states = ['ACTIVE','ONLINE','OFFLINE','LOST','RECOVERING','RECOVERED','DISABLED','PENDING'];
    expect(states).toContain('LOST');
  });
  it('defines location sources', ()=>{
    const sources = ['GPS','NETWORK','CELLULAR','NEARBY','FINDER','UNKNOWN'];
    expect(sources).toContain('GPS');
  });
});
