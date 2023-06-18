import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('TMSAFToken', () => {
  const deployContract = async () => {
    const [owner, address1, address2, address3] = await ethers.getSigners();
    const TMSAFToken = await ethers.getContractFactory('TMSAFToken');
    const tMSAFToken = await TMSAFToken.deploy();

    return { tMSAFToken, owner, address1, address2, address3 };
  };

  describe('Constructor part', () => {
    it('Should give owner 999 tokens', async () => {
      const { tMSAFToken, owner } = await deployContract();

      expect(await tMSAFToken.balanceOf(owner.address)).to.be.equal(999);
    });

    it('Should have increased totalSupply by 999', async () => {
      const { tMSAFToken } = await deployContract();

      expect(await tMSAFToken.totalSupply()).to.be.equal(999);
    });
  });
});
