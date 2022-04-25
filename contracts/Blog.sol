//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Blog {
    string public name;
    address public owner;

    using Counters for Counters.Counter;
    Counters.Counter private _postIds;

    struct Post {
        uint id;
        string title;
        string content;
        bool published;
    }

    mapping(uint => Post) private idToPost;
    mapping(string => Post) private hashToPost;

    event PostCreated(uint id, string title, string hash);
    event PostUpdated(uint id, string title, string hash, bool published);

    // I think what's going on here is that you can add the optional variable "memory" to ensure that the data is not stored in either (1) storage which is expensive or (2) calldata. Not sure why it shouldn't just be stored as calldata.
    constructor(string memory _name) {
        console.log("Deploying blog with name:", _name);
        name = _name;
        owner = msg.sender;
    }

    // what does this actually do when the function updateName("testName") is called? specifically the variable declaration. Does this change anything in storage? Where? I don't get it
    function updateName(string memory _name) public {
        name = _name;
    }
    // Ah - name is not a property of a post. It's more like metadata and is associated with the contract itself. This Blog contract has a 'name' property, think of it like the name of the blog itself. Since you are changing the string defined in 8, you are changing the name

    // ditto here
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    // Neat, I didn't know about modifiers before. Handy.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // weird that you don't use the ID but use a hash instead to search your posts...
    // And why do we specify that the Post object we return has to be in memory? W e i r d
    function fetchPost(string memory hash) public view returns(Post memory) {
        return hashToPost[hash];
    }

    function createPost(string memory title, string memory hash) public onlyOwner {
        _postIds.increment();
        uint postId = _postIds.current();

        // first, since you created a struct earlier, you can just create an object and ensure it's stored in storage (as opposed to memory or calldata) by writing Post storage <variableName> = <theThingYou'reCreating>
        // here we define <theThingYou'reCreating> by using the mapping idToPost and feeding it the new id

        // really don't understand this. Which bit is actually doing the creating? shouldn't it be << idToPost[postId] = Post storage post >> ? Since we know what is on the right side but not what is on the left?

        // ah - from the docs: Mappings can be seen as hash tables which are virtually initialized such that every possible key exists and is mapped to a value whose byte-representation is all zeros: a type’s default value.

        // so basically idToPost[withLiterallyAnythingInHere] returns a post, and that post will almost always have null values for every property

        // Post storage post = somePostObject will take that object, whack it in storage, and assign it to the variable name "post". Since solidity is statically typed, we can't just declare a variable without also declaring its type, so we declare it - as Post. In the same way that you'd write "string public name"

        Post storage post = idToPost[postId];

        // this is the standard way to create objects in Solidity (see https://docs.soliditylang.org/en/v0.8.13/types.html#structs)

        post.id = postId;
        post.title = title;
        post.published = true;
        post.content = hash;

        // note there is no sense of pressing the 'save' button - when you perform operations on post, it's saved in storage
        
        // here we update the hashToPost mapping too, since it currently points at a post with null values
        hashToPost[hash] = post;
        emit PostCreated(postId, title, hash);
    }

    // I don't understand why some of these variables are declared with memory and some not
    function updatePost(uint postId, string memory title, string memory hash, bool published) public onlyOwner {
        // I think another reason specifying storage here may be important is so that when you do make modifications to post, you're not making modiciations to a separate carbon copy object in memory called post but rather the original post itself in storage
        Post storage post = idToPost[postId];
        post.title = title;
        post.content = hash;
        post.published = published;
        // what is super weird is that we have to update the mappings as well as the storage itself...
        idToPost[postId] = post;
        hashToPost[hash] = post;
        emit PostUpdated(postId, title, hash, published);
    }

    // I think the syntax here is that when you want to return an array of a type rather than a single object of that type, you just write Struct [] and if you want to specify that it comes from (or is stored in?) memory rather than e.g. storage you write memory afterwards?
    function fetchPosts() public view returns (Post [] memory) {
        uint itemCount = _postIds.current();

        // I think new Post[](num) just creates an array of Post objects with length num, and Post[] memory posts puts that thing in memory and lets you play with it with the variable 'posts'
        Post[] memory posts = new Post[](itemCount);
        for (uint i = 0; i < itemCount; i++) {
            uint currentId = i + 1;
            Post storage currentItem = idToPost[currentId];
            posts[i] = currentItem;
        }
        return posts;
    }
}