const MLMNode = require('../models/MLMNode');
const User = require('../models/User');
const Commission = require('../models/Commission');
const MLMSettings = require('../models/MLMSettings');
const Withdrawal = require('../models/Withdrawal');

// Create MLM node for a new user
const createMLMNode = async (userId, sponsorId) => {
  try {
    let parentNode = null;
    let position = 'root';

    if (sponsorId) {
      // Find sponsor's node
      const sponsorNode = await MLMNode.findOne({ userId: sponsorId });
      if (sponsorNode) {
        // Find the first available position in BFS order under sponsor
        const available = await findAvailablePosition(sponsorNode._id);
        if (available) {
          parentNode = available.node;
          position = available.position;
        }
      }
    } else {
      // Check if root node exists
      const rootNode = await MLMNode.findOne({ parentId: null });
      if (!rootNode) {
        // This is the first node (root)
        const newNode = await MLMNode.create({
          userId,
          parentId: null,
          sponsorId: null,
          position: 'root',
          level: 0,
        });
        return newNode;
      } else {
        // Find available position in entire tree
        const available = await findAvailablePosition(rootNode._id);
        if (available) {
          parentNode = available.node;
          position = available.position;
        }
      }
    }

    if (!parentNode) {
      // Fallback: create as root level
      const newNode = await MLMNode.create({
        userId,
        parentId: null,
        sponsorId,
        position: 'left',
        level: 0,
      });
      return newNode;
    }

    const level = (await MLMNode.findById(parentNode._id))?.level + 1 || 1;

    const newNode = await MLMNode.create({
      userId,
      parentId: parentNode._id,
      sponsorId,
      position,
      level,
    });

    // Update parent's child reference
    if (position === 'left') {
      await MLMNode.findByIdAndUpdate(parentNode._id, { leftChild: newNode._id });
    } else {
      await MLMNode.findByIdAndUpdate(parentNode._id, { rightChild: newNode._id });
    }

    // Update team counts up the tree
    await updateAncestorCounts(parentNode._id, position);

    return newNode;
  } catch (error) {
    console.error('createMLMNode error:', error);
    throw error;
  }
};

// BFS to find first available position under a node
const findAvailablePosition = async (rootNodeId) => {
  const queue = [rootNodeId];
  while (queue.length > 0) {
    const nodeId = queue.shift();
    const node = await MLMNode.findById(nodeId);
    if (!node) continue;

    if (!node.leftChild) return { node, position: 'left' };
    if (!node.rightChild) return { node, position: 'right' };

    queue.push(node.leftChild);
    queue.push(node.rightChild);
  }
  return null;
};

// Place user manually at specific position
const placeUserManually = async (userId, parentUserId, position) => {
  const parentNode = await MLMNode.findOne({ userId: parentUserId });
  if (!parentNode) throw new Error('Parent node not found');

  if (position === 'left' && parentNode.leftChild) {
    throw new Error('Left position is already occupied');
  }
  if (position === 'right' && parentNode.rightChild) {
    throw new Error('Right position is already occupied');
  }

  let existingNode = await MLMNode.findOne({ userId });
  const level = parentNode.level + 1;

  if (existingNode) {
    // Move node
    existingNode.parentId = parentNode._id;
    existingNode.position = position;
    existingNode.level = level;
    await existingNode.save();
  } else {
    existingNode = await MLMNode.create({
      userId,
      parentId: parentNode._id,
      sponsorId: parentUserId,
      position,
      level,
    });
  }

  if (position === 'left') {
    await MLMNode.findByIdAndUpdate(parentNode._id, { leftChild: existingNode._id });
  } else {
    await MLMNode.findByIdAndUpdate(parentNode._id, { rightChild: existingNode._id });
  }

  await updateAncestorCounts(parentNode._id, position);
  return existingNode;
};

// Update all ancestors' counts
const updateAncestorCounts = async (nodeId, addedPosition) => {
  let currentId = nodeId;
  while (currentId) {
    const node = await MLMNode.findById(currentId);
    if (!node) break;

    // Recalculate left/right counts from children
    const leftCount = node.leftChild ? await getSubtreeCount(node.leftChild) : 0;
    const rightCount = node.rightChild ? await getSubtreeCount(node.rightChild) : 0;

    await MLMNode.findByIdAndUpdate(currentId, {
      leftCount,
      rightCount,
      totalTeamSize: leftCount + rightCount,
    });

    currentId = node.parentId;
  }
};

const getSubtreeCount = async (nodeId) => {
  if (!nodeId) return 0;
  const node = await MLMNode.findById(nodeId);
  if (!node) return 0;
  const left = node.leftChild ? await getSubtreeCount(node.leftChild) : 0;
  const right = node.rightChild ? await getSubtreeCount(node.rightChild) : 0;
  return 1 + left + right;
};

// Process commissions when a course is purchased
const processCommissions = async (buyerUserId, courseId, coursePrice, transactionId) => {
  try {
    const settings = await MLMSettings.findOne({ singleton: true });
    if (!settings) return;

    const commissions = [];

    // 1. Direct Referral Commission (to sponsor)
    const buyer = await User.findById(buyerUserId);
    if (buyer && buyer.sponsorId) {
      const directCommAmount = (coursePrice * settings.directReferralCommission) / 100;
      commissions.push({
        userId: buyer.sponsorId,
        fromUserId: buyerUserId,
        transactionId,
        courseId,
        type: 'direct_referral',
        level: 1,
        percentage: settings.directReferralCommission,
        baseAmount: coursePrice,
        amount: directCommAmount,
        description: `Direct referral commission for course purchase`,
      });
    }

    // 2. Level Override Commissions (upline levels)
    const buyerNode = await MLMNode.findOne({ userId: buyerUserId });
    if (buyerNode && settings.levelCommissions) {
      let currentNodeId = buyerNode.parentId;
      let level = 1;

      while (currentNodeId && level <= settings.levelCommissions.length) {
        const currentNode = await MLMNode.findById(currentNodeId);
        if (!currentNode) break;

        const levelSetting = settings.levelCommissions.find(l => l.level === level);
        if (levelSetting && levelSetting.percentage > 0) {
          // Skip if this is the direct referral (already counted)
          const isDirect = buyer?.sponsorId?.toString() === currentNode.userId?.toString();
          if (!isDirect) {
            const levelCommAmount = (coursePrice * levelSetting.percentage) / 100;
            commissions.push({
              userId: currentNode.userId,
              fromUserId: buyerUserId,
              transactionId,
              courseId,
              type: 'level_override',
              level,
              percentage: levelSetting.percentage,
              baseAmount: coursePrice,
              amount: levelCommAmount,
              description: `Level ${level} override commission`,
            });
          }
        }

        currentNodeId = currentNode.parentId;
        level++;
      }
    }

    // 3. Binary Matching Bonus (processed separately on schedule)
    // Update volumes on the binary tree
    await updateBinaryVolumes(buyerUserId, coursePrice);

    // Insert all commissions
    if (commissions.length > 0) {
      const inserted = await Commission.insertMany(commissions);

      // Credit wallet balances
      for (const comm of commissions) {
        await User.findByIdAndUpdate(comm.userId, {
          $inc: { walletBalance: comm.amount, totalEarnings: comm.amount },
        });
      }

      // Emit real-time notification via socket if available
      return inserted;
    }
    return [];
  } catch (error) {
    console.error('processCommissions error:', error);
    throw error;
  }
};

// Update binary volume for ancestor nodes
const updateBinaryVolumes = async (userId, amount) => {
  const userNode = await MLMNode.findOne({ userId });
  if (!userNode) return;

  let currentId = userNode.parentId;
  let childId = userNode._id;

  while (currentId) {
    const parentNode = await MLMNode.findById(currentId);
    if (!parentNode) break;

    if (parentNode.leftChild?.toString() === childId.toString()) {
      await MLMNode.findByIdAndUpdate(currentId, { $inc: { leftVolume: amount } });
    } else if (parentNode.rightChild?.toString() === childId.toString()) {
      await MLMNode.findByIdAndUpdate(currentId, { $inc: { rightVolume: amount } });
    }

    childId = parentNode._id;
    currentId = parentNode.parentId;
  }
};

// Get full binary tree for a user
const getTreeData = async (userId, depth = 4) => {
  const node = await MLMNode.findOne({ userId }).populate('userId', 'name email profilePicture rank');
  if (!node) return null;
  return await buildTree(node, depth, 0);
};

const buildTree = async (node, maxDepth, currentDepth) => {
  if (!node || currentDepth > maxDepth) return null;
  const user = await User.findById(node.userId).select('name email profilePicture rank isActive');
  const treeNode = {
    id: node._id,
    userId: node.userId,
    user,
    position: node.position,
    level: node.level,
    leftVolume: node.leftVolume,
    rightVolume: node.rightVolume,
    leftCount: node.leftCount,
    rightCount: node.rightCount,
    left: null,
    right: null,
  };

  if (node.leftChild && currentDepth < maxDepth) {
    const leftNode = await MLMNode.findById(node.leftChild);
    treeNode.left = await buildTree(leftNode, maxDepth, currentDepth + 1);
  }
  if (node.rightChild && currentDepth < maxDepth) {
    const rightNode = await MLMNode.findById(node.rightChild);
    treeNode.right = await buildTree(rightNode, maxDepth, currentDepth + 1);
  }

  return treeNode;
};

module.exports = {
  createMLMNode,
  placeUserManually,
  findAvailablePosition,
  processCommissions,
  updateBinaryVolumes,
  getTreeData,
  buildTree,
};
