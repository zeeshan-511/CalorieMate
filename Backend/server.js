require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require('http');

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Middlewares
app.use(cors());
app.use(express.json());

// MongoDB Connection
const MONGO_URI = process.env.MONGO_URI || "mongodb://zshoukat310_db_user:zeeshan1234@ac-hm0gqer-shard-00-00.txjhg3k.mongodb.net:27017,ac-hm0gqer-shard-00-01.txjhg3k.mongodb.net:27017,ac-hm0gqer-shard-00-02.txjhg3k.mongodb.net:27017/?ssl=true&replicaSet=atlas-13y8hx-shard-0&authSource=admin&appName=Cluster0";

mongoose.connect(MONGO_URI)
  .then(() => console.log("Connected to Mongodb Atlas"))
  .catch((err) => console.error("MongoDB connection error:", err));

// User Schema (Updated with familyMembers array)
const userSchema = new mongoose.Schema({
  fullName: { type: String },
  email: { type: String, required: true, unique: true },
  password: { type: String },
  mobileNumber: { type: String },
  dateOfBirth: { type: String },
  googleId: { type: String },
  familyMembers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'FamilyMember' }],
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model("User", userSchema);

// Family Member Schema
const familyMemberSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  age: { type: Number, required: true },
  gender: { type: String, enum: ['Male', 'Female', 'Other'], required: true },
  relation: { type: String, required: true },
  weight: { type: String },
  healthConditions: [{ type: String }],
  isPrimary: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const FamilyMember = mongoose.model("FamilyMember", familyMemberSchema);

// ============================================
// AUTHENTICATION MIDDLEWARE
// ============================================

// Simple authentication middleware
const auth = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];

    // For now, we'll just check if token exists
    // In a production app, you'd verify JWT here
    // For simplicity, we'll just pass through
    // You can implement proper JWT verification later

    next();
  } catch (error) {
    console.error('Auth error:', error);
    res.status(401).json({ message: 'Invalid token' });
  }
};

// ============================================
// EXISTING ROUTES
// ============================================

// Health Check
app.get("/", (req, res) => res.send("Server is running!"));

// REGISTER
app.post('/register', async (req, res) => {
  try {
    const user = await User.create(req.body);
    if (!user) return res.status(403).json({ message: "User registration failed" });
    res.status(201).json({ message: "User registered Successfully", user });
  } catch (err) {
    console.error("Register error:", err);
    res.status(500).json({ message: err.message });
  }
});

// LOGIN
app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.password !== password) {
      return res.status(401).json({ message: "Invalid password" });
    }

    // Check if this user has any family members
    const familyMembers = await FamilyMember.find({ userId: user._id });
    const hasFamilyMembers = familyMembers.length > 0;

    res.status(200).json({
      message: "Login successful",
      user,
      hasFamilyMembers,
      token: "dummy-token-" + user._id // Simple token for now
    });

  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// Regular Sign Up
app.post("/api/signup", async (req, res) => {
  const { fullName, email, password, mobileNumber, dateOfBirth } = req.body;
  try {
    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ error: "Email already registered" });

    const user = new User({ fullName, email, password, mobileNumber, dateOfBirth });
    await user.save();

    res.status(201).json({
      message: "User created",
      user,
      token: "dummy-token-" + user._id
    });
  } catch (err) {
    console.error("Signup error:", err);
    res.status(500).json({ error: err.message });
  }
});

// Google Sign-In
app.post("/api/google-login", async (req, res) => {
  const { name, email, googleId } = req.body;
  try {
    let user = await User.findOne({ email });
    if (!user) {
      user = new User({ fullName: name, email, googleId });
      await user.save();
    }

    // Check if this user has any family members
    const familyMembers = await FamilyMember.find({ userId: user._id });
    const hasFamilyMembers = familyMembers.length > 0;

    res.status(200).json({
      message: "User logged in",
      user,
      hasFamilyMembers,
      token: "dummy-token-" + user._id
    });
  } catch (err) {
    console.error("Google login error:", err);
    res.status(500).json({ error: err.message });
  }
});

// MongoDB Test Route
app.get("/api/test-db", async (req, res) => {
  try {
    const collections = await mongoose.connection.db.listCollections().toArray();
    res.status(200).json({
      message: "MongoDB connected!",
      collections: collections.map(c => c.name),
    });
  } catch (err) {
    res.status(500).json({ error: "MongoDB connection failed", details: err.message });
  }
});

// ============================================
// FAMILY MEMBER ROUTES
// ============================================

// Get all family members for a user
app.get('/family-members/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;

    // Validate userId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    const familyMembers = await FamilyMember.find({ userId }).sort({ isPrimary: -1, createdAt: 1 });
    res.json(familyMembers);
  } catch (error) {
    console.error('Error fetching family members:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Add a new family member
app.post('/family-members', auth, async (req, res) => {
  try {
    const { userId, name, age, gender, relation, weight, healthConditions } = req.body;

    // Validate required fields
    if (!userId || !name || !age || !gender || !relation) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Validate userId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if this is the first member for this user
    const existingMembers = await FamilyMember.find({ userId });
    const isPrimary = existingMembers.length === 0;

    const newMember = new FamilyMember({
      userId,
      name,
      age,
      gender,
      relation,
      weight,
      healthConditions: healthConditions || [],
      isPrimary
    });

    await newMember.save();

    // Update user's familyMembers array
    await User.findByIdAndUpdate(userId, {
      $push: { familyMembers: newMember._id }
    });

    res.status(201).json(newMember);
  } catch (error) {
    console.error('Error adding family member:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update a family member
app.put('/family-members/:memberId', auth, async (req, res) => {
  try {
    const { memberId } = req.params;
    const updates = req.body;

    // Validate memberId
    if (!mongoose.Types.ObjectId.isValid(memberId)) {
      return res.status(400).json({ message: 'Invalid member ID' });
    }

    const member = await FamilyMember.findById(memberId);
    if (!member) {
      return res.status(404).json({ message: 'Family member not found' });
    }

    // Don't allow updating isPrimary through this route
    delete updates.isPrimary;
    delete updates.userId;

    const updatedMember = await FamilyMember.findByIdAndUpdate(
      memberId,
      { $set: updates },
      { new: true }
    );

    res.json(updatedMember);
  } catch (error) {
    console.error('Error updating family member:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Delete a family member
app.delete('/family-members/:memberId', auth, async (req, res) => {
  try {
    const { memberId } = req.params;

    // Validate memberId
    if (!mongoose.Types.ObjectId.isValid(memberId)) {
      return res.status(400).json({ message: 'Invalid member ID' });
    }

    const member = await FamilyMember.findById(memberId);
    if (!member) {
      return res.status(404).json({ message: 'Family member not found' });
    }

    // Prevent deletion of primary member
    if (member.isPrimary) {
      return res.status(400).json({ message: 'Cannot delete primary family member' });
    }

    await FamilyMember.findByIdAndDelete(memberId);

    // Remove from user's familyMembers array
    await User.findByIdAndUpdate(member.userId, {
      $pull: { familyMembers: memberId }
    });

    res.json({ message: 'Family member deleted successfully' });
  } catch (error) {
    console.error('Error deleting family member:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get a single family member by ID
app.get('/family-members/member/:memberId', auth, async (req, res) => {
  try {
    const { memberId } = req.params;

    // Validate memberId
    if (!mongoose.Types.ObjectId.isValid(memberId)) {
      return res.status(400).json({ message: 'Invalid member ID' });
    }

    const member = await FamilyMember.findById(memberId);
    if (!member) {
      return res.status(404).json({ message: 'Family member not found' });
    }

    res.json(member);
  } catch (error) {
    console.error('Error fetching family member:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get family member count for a user
app.get('/family-members/count/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;

    // Validate userId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    const count = await FamilyMember.countDocuments({ userId });
    res.json({ count });
  } catch (error) {
    console.error('Error counting family members:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// ============================================
// USER ROUTES (Additional)
// ============================================

// Get user profile with family members
app.get('/user/:userId/profile', auth, async (req, res) => {
  try {
    const { userId } = req.params;

    // Validate userId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    const user = await User.findById(userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const familyMembers = await FamilyMember.find({ userId });

    res.json({
      user,
      familyMembers,
      totalMembers: familyMembers.length
    });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!', error: err.message });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Start Server
const PORT = process.env.PORT || 9000;
server.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));