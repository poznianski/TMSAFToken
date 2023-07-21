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

  describe('Transfer function', () => {
    it('Should be able to transfer tokens', async () => {
      const { tMSAFToken, owner, address1, address2 } = await deployContract();

      await tMSAFToken.connect(owner).transfer(address1.address, 123);
      await tMSAFToken.connect(owner).transfer(address2.address, 54);

      expect(await tMSAFToken.balanceOf(address1.address)).to.be.equal(123);
      expect(await tMSAFToken.balanceOf(address2.address)).to.be.equal(54);

      await tMSAFToken.connect(address1).transfer(address2.address, 50);

      expect(await tMSAFToken.balanceOf(address1.address)).to.be.equal(73);
      expect(await tMSAFToken.balanceOf(address2.address)).to.be.equal(104);
    });

    it('Should not allow transfers that exceed the balance', async () => {
      const { tMSAFToken, owner, address1 } = await deployContract();

      await expect(
        tMSAFToken.connect(owner).transfer(address1.address, 1000),
      ).to.be.revertedWith('must have a balance of at least amount');
    });

    it('Should not allow transfers to zero address', async () => {
      const { tMSAFToken, owner } = await deployContract();

      await expect(
        tMSAFToken.connect(owner).transfer(ethers.ZeroAddress, 100),
      ).to.be.revertedWith('sender cannot be the zero address');
    });
  });

  describe('Approve function', () => {
    it('Should return the correct allowance', async () => {
      const { tMSAFToken, owner, address1 } = await deployContract();

      await tMSAFToken.connect(owner).approve(address1.address, 50);

      const allowance = await tMSAFToken.allowance(
        owner.address,
        address1.address,
      );
      expect(allowance).to.equal(50);
    });

    it('Should revert when the owner address is zero', async () => {
      const { tMSAFToken, address1 } = await deployContract();

      await expect(
        tMSAFToken.allowance(ethers.ZeroAddress, address1.address),
      ).to.be.revertedWith('Owner address cannot be zero');
    });

    it('Should revert when the spender address is zero', async () => {
      const { tMSAFToken, owner } = await deployContract();

      await expect(
        tMSAFToken.allowance(owner.address, ethers.ZeroAddress),
      ).to.be.revertedWith('Spender address cannot be zero');
    });
  });

  describe('Buy function', () => {
    it('Should allow buying tokens', async () => {
      const { tMSAFToken, address1 } = await deployContract();

      await tMSAFToken.connect(address1).buy({ value: 16 });

      expect(await tMSAFToken.balanceOf(address1.address)).to.be.equal(16);
    });

    it('Should not allow buying tokens with insufficient ether', async () => {
      const { tMSAFToken, address1 } = await deployContract();

      await expect(
        tMSAFToken.connect(address1).buy({ value: 0 }),
      ).to.be.revertedWith('Insufficient ether sent to buy tokens');

      expect(await tMSAFToken.balanceOf(address1.address)).to.be.equal(0);
    });
  });

  describe('Sell function', () => {
    it('Should allow sell tokens', async () => {
      const { tMSAFToken, address1 } = await deployContract();

      await tMSAFToken.connect(address1).buy({ value: 16 });
      expect(await tMSAFToken.balanceOf(address1.address)).to.be.equal(16);

      await tMSAFToken.connect(address1).sell(16);
      expect(await tMSAFToken.balanceOf(address1.address)).to.be.equal(0);
    });
  });

  describe('TransferFrom, Allowance, Approve function', () => {
    it('Should allow approved address to transfer tokens', async () => {
      const { tMSAFToken, owner, address1 } = await deployContract();

      await tMSAFToken.connect(owner).approve(address1.address, 50);

      expect(
        await tMSAFToken.allowance(owner.address, address1.address),
      ).to.be.equal(50);

      await tMSAFToken
        .connect(address1)
        .transferFrom(owner.address, address1.address, 20);

      expect(await tMSAFToken.balanceOf(address1.address)).to.be.equal(20);
      expect(await tMSAFToken.balanceOf(owner.address)).to.be.equal(979);
      expect(
        await tMSAFToken.allowance(owner.address, address1.address),
      ).to.be.equal(30);
    });
  });

  describe('Burn function', () => {
    it('Should correctly burn tokens', async () => {
      const { tMSAFToken, owner } = await deployContract();

      await tMSAFToken.burnFromOwner(99);
      expect(await tMSAFToken.totalSupply()).to.be.equal(900);
      expect(await tMSAFToken.balanceOf(owner.address)).to.be.equal(900);
    });

    it('Should not burn more tokens than available', async () => {
      const { tMSAFToken, owner } = await deployContract();

      await expect(tMSAFToken.burnFromOwner(1000)).to.be.revertedWith(
        'must have at least amount tokens',
      );
    });
  });
});
