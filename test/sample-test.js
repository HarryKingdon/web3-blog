const { expect } = require('chai')
const { ethers } = require('hardhat')

// when you're writing tests in hardhat, there is no persistent network that retains your smart contract once you re-initialise the smart contract with getContractFactory. The contract is re-compiled every time.

describe('Blog', async function () {
  it('Should create a post', async function () {
    const Blog = await ethers.getContractFactory('Blog')
    const blog = await Blog.deploy('My blog')
    // also never been confident enough before to use await like this without .then
    await blog.deployed()
    await blog.createPost('My first post', '12345')

    const posts = await blog.fetchPosts()
    expect(posts[0].title).to.equal('My first post')
  })

  it('Should edit a post', async function () {
    const Blog = await ethers.getContractFactory('Blog')
    const blog = await Blog.deploy('My blog')
    await blog.deployed()
    await blog.createPost('My Second post', '12345')

    await blog.updatePost(1, 'My updated post', '23456', true)

    posts = await blog.fetchPosts()
    expect(posts[0].title).to.equal('My updated post')
  })

  it('Should add update the name', async function () {
    const Blog = await ethers.getContractFactory('Blog')
    const blog = await Blog.deploy('My blog')
    await blog.deployed()

    expect(await blog.name()).to.equal('My blog')
    await blog.updateName('My new blog')
    expect(await blog.name()).to.equal('My new blog')
  })
})
