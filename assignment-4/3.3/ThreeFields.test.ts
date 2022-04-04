import { Field, isReady, shutdown } from 'snarkyjs';
import { run } from './ThreeFields';

describe('ThreeFields', () => {
    beforeAll(async () => {
        await isReady;
    });
    afterAll(async () => {
        await shutdown();
    it('should equal 1337', async () => {
        const res = run();
        expect(res).toEqual(new Field(1337));

    });
})});