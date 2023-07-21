import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect, assert } from 'chai';
import { ethers } from 'hardhat';

describe('Votable', () => {
  const deployContract = async () => {
    const [owner, address1, address2] = await ethers.getSigners();
    const Votable = await ethers.getContractFactory('VotingContract');

    const votable = await Votable.deploy();

    return { votable, owner, address1, address2 };
  };

  describe('Voting', () => {
    it('should not allow voting if voting has not started', async () => {
      const { votable, owner, address1 } = await deployContract();

      await votable.connect(owner).transfer(address1.address, 25);

      await expect(
        votable
          .connect(address1)
          .vote(10, ethers.ZeroAddress, ethers.ZeroAddress),
      ).to.be.revertedWith('Voting has not started yet');
    });

    it('Voter should have more than 0.05% of total token supply', async () => {
      const { votable, address1 } = await deployContract();
      await votable.startVoting();

      await expect(
        votable
          .connect(address1)
          .vote(10, ethers.ZeroAddress, ethers.ZeroAddress),
      ).to.be.revertedWith(
        'Voter should have more than 0.05% of total token supply',
      );
    });

    it('should not allow voting if the proposed price is 0', async () => {
      const { owner, votable, address1 } = await deployContract();

      await votable.startVoting();
      await votable.connect(owner).transfer(address1.address, 5);

      await expect(
        votable
          .connect(address1)
          .vote(0, ethers.ZeroAddress, ethers.ZeroAddress),
      ).to.be.revertedWith('Price should be more than 0');
    });

    it('should allow voting if the user has a token and the voting has started', async () => {
      const { votable, owner, address1 } = await deployContract();
      await votable.startVoting();
      await votable.connect(owner).transfer(address1.address, 5);

      const tx = await votable
        .connect(address1)
        .vote(10, ethers.ZeroAddress, ethers.ZeroAddress);
      await tx.wait();
      expect(tx).to.emit(votable, 'Vote');
    });

    it('should increase totalVotesCount after voting', async () => {
      const { votable, owner, address1 } = await deployContract();
      await votable.startVoting();
      await votable.connect(owner).transfer(address1.address, 5);

      await votable
        .connect(address1)
        .vote(10, ethers.ZeroAddress, ethers.ZeroAddress);

      expect(await votable.totalVotesCount()).to.equal(1);
    });

    it('should correctly increase totalVotesCount after voting', async () => {
      const { votable, owner, address1 } = await deployContract();
      await votable.startVoting();

      await votable.connect(owner).transfer(address1.address, 5);
      await votable
        .connect(address1)
        .vote(15, ethers.ZeroAddress, ethers.ZeroAddress);

      expect(await votable.totalVotesCount()).to.equal(1);
    });

    it('Should set token price', async () => {
      const { votable, owner, address1, address2 } = await deployContract();

      await votable
        .connect(address1)
        .buyTokens(ethers.ZeroAddress, ethers.ZeroAddress, ethers.ZeroAddress, {
          value: ethers.parseEther('0.4'),
        });
      expect(
        Number(await votable.balanceOf(address1.address)),
      ).to.be.greaterThan(0);

      await votable.startVoting();

      await votable
        .connect(address1)
        .vote(22, ethers.ZeroAddress, ethers.ZeroAddress);

      expect(Number(await votable.totalVotesCount())).to.be.greaterThan(0);
      expect(await votable.voters(address1.address)).to.equal(
        ethers.ZeroAddress,
      );

      const pricesList = await votable.connect(address1).getPricesList();
      assert.isNotEmpty(pricesList);

      await ethers.provider.send('evm_increaseTime', [86400]);
      await ethers.provider.send('evm_mine');

      await votable.endVoting();

      expect(await votable.getTokenPrice()).to.be.equal(22);
    });
  });
});
