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

  // describe('StartVoting', () => {
  //   it('Should change votingStartedTime, votingNumber, and emit VotingStarted event', async () => {
  //     const { tMSAFToken, owner } = await deployContract();

  //     await tMSAFToken.startVoting();

  //     const votingStartedTime = await tMSAFToken.startVoting();

  //     expect(votingStartedTime).to.not.equal(0);

  //     // Check if VotingStarted event is emitted
  //     const startVotingEvents = await tMSAFToken.queryFilter(
  //       tMSAFToken.filters.VotingStarted(),
  //     );
  //     expect(startVotingEvents.length).to.equal(1);
  //   });
  // });

  describe('_updateVotingPower function', () => {
    it('Should update the voting power and select a new winner when necessary', async () => {
      const { tMSAFToken, owner, address1, address2 } = await deployContract();

      await tMSAFToken.connect(address1).buy({ value: 16 });
      await tMSAFToken.connect(address1).buy({ value: 14 });

      await tMSAFToken.connect(owner).startVoting();
      await tMSAFToken.connect(address1).vote(0);
      await tMSAFToken.connect(address2).vote(1);

      expect(await tMSAFToken.votingPower(address1.address)).to.be.equal(123);
      expect(await tMSAFToken.votingPower(address2.address)).to.be.equal(54);
      expect(await tMSAFToken.currentPriceOption()).to.be.equal(0);

      await tMSAFToken.connect(address1).transfer(address2.address, 50);

      expect(await tMSAFToken.votingPower(address1.address)).to.be.equal(73);
      expect(await tMSAFToken.votingPower(address2.address)).to.be.equal(104);
      expect(await tMSAFToken.currentPriceOption()).to.be.equal(1);
    });
  });
});
