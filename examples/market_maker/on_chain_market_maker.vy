from vyper.interfaces import ERC20

tokenAQty: public(uint256) #Quantity of tokenA held by the contract
tokenBQty: public(uint256) #Quantity of tokenB held by the contract

invariant: public(uint256) #The Constant-Function invariant (tokenAQty*tokenBQty = invariant throughout the life of the contract)
tokenA: ERC20 #The ERC20 contract for tokenA
tokenB: ERC20 #The ERC20 contract for tokenB
owner: public(address) #The liquidity provider (the address that has the right to withdraw funds and close the contract)

@external
def get_token_address(token: uint256) -> address:
	if token == 0:
		return self.tokenA.address
	if token == 1:
		return self.tokenB.address
	return ZERO_ADDRESS	

# Sets the on chain market maker with its owner, and initial token quantities
@external
def provideLiquidity(tokenA_addr: address, tokenB_addr: address, tokenA_quantity: uint256, tokenB_quantity: uint256):
	assert self.invariant == 0 #This ensures that liquidity can only be provided once
	#Your code here
	# Getting token addresses
	self.tokenA = ERC20(tokenA_addr)
	self.tokenB = ERC20(tokenB_addr)
	# Getting token qtys
	self.tokenAQty = tokenA_quantity
	self.tokenBQty = tokenB_quantity
	# Transfer information
	self.tokenA.transferFrom(msg.sender, self, tokenA_quantity)
	self.tokenB.transferFrom(msg.sender, self, tokenB_quantity)
	self.owner = msg.sender

	# Calculate liquidity
	self.invariant = self.tokenAQty * self.tokenBQty

	assert self.invariant > 0

# Trades one token for the other
@external
def tradeTokens(sell_token: address, sell_quantity: uint256):
	assert sell_token == self.tokenA.address or sell_token == self.tokenB.address
	#Your code here

	#Check which token is traded

	# if A is traded for B

	if sell_token == self.tokenA.address:
		self.tokenA.transferFrom(msg.sender, self, sell_quantity)
		
		new_tokenA_qty: uint256 = self.tokenAQty + sell_quantity
		new_tokenB_qty: uint256 = self.invariant/new_tokenA_qty


		# send to trader
		tokenB_sent_to_trader: uint256 = self.tokenBQty - new_tokenB_qty
		self.tokenB.transfer(msg.sender, tokenB_sent_to_trader)

		# update new token qtys on uniswap_exchange
		self.tokenAQty = new_tokenA_qty
		self.tokenBQty = new_tokenB_qty

	# if B is traded for A
	else:
		self.tokenA.transferFrom(msg.sender, self, sell_quantity)
		
		new_tokenB_qty: uint256 = self.tokenBQty + sell_quantity
		new_tokenA_qty: uint256 = self.invariant/new_tokenB_qty


		# send to trader
		tokenA_sent_to_trader: uint256 = self.tokenAQty - new_tokenA_qty
		self.tokenA.transfer(msg.sender, tokenA_sent_to_trader)

		# update new token qtys on uniswap_exchange
		self.tokenAQty = new_tokenA_qty
		self.tokenBQty = new_tokenB_qty


# Owner can withdraw their funds and destroy the market maker
@external
def ownerWithdraw():
	assert self.owner == msg.sender
	#Your code here

	# withdraw funds/transfer funds
	self.tokenA.transfer(self.owner, self.tokenAQty)
	self.tokenB.transfer(self.owner, self.tokenBQty)
	selfdestruct(self.owner)
