require("dotenv").config();

const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const axios = require("axios");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
let nodemailer = null;
try {
  nodemailer = require("nodemailer");
} catch (_) {}

const app = express();
const server = http.createServer(app);

app.use(cors());
app.use(express.json());

const MONGO_URI =
  process.env.MONGO_URI ||
  "mongodb://127.0.0.1:27017/caloriemate";

if (process.env.CALORIEMATE_SKIP_MONGO !== "1") {
  mongoose
    .connect(MONGO_URI)
    .then(async () => {
      console.log("Connected to MongoDB");
      await fixPreferenceIndexes();
    })
    .catch((err) => console.error("MongoDB connection error:", err));
}






const userSchema = new mongoose.Schema({
  fullName: { type: String },
  email: { type: String, required: true, unique: true },
  password: { type: String },
  mobileNumber: { type: String },
  dateOfBirth: { type: String },
  googleId: { type: String },
  settings: {
    emailNotifications: { type: Boolean, default: true },
    familySharing: { type: Boolean, default: true },
    saveScanHistory: { type: Boolean, default: true },
    recommendationAlerts: { type: Boolean, default: true },
  },
  passwordResetTokenHash: { type: String, default: "", index: true },
  passwordResetExpiresAt: { type: Date, default: null },
  passwordResetUsedAt: { type: Date, default: null },
  lastLoginAt: { type: Date, default: null },
  familyMembers: [{ type: mongoose.Schema.Types.ObjectId, ref: "FamilyMember" }],
  createdAt: { type: Date, default: Date.now },
});

const User = mongoose.model("User", userSchema);






const familyMemberSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    name: { type: String, required: true },
    age: { type: Number, default: 1 },
    gender: {
      type: String,
      enum: ["Male", "Female", "Other"],
      default: "Other",
    },
    relation: { type: String, default: "Family" },
    weight: { type: String, default: "" },
    healthConditions: [{ type: String }],
    isPrimary: { type: Boolean, default: false },
    invitationEmail: { type: String, default: "", lowercase: true, trim: true, index: true },
    invitationStatus: {
      type: String,
      enum: ["local_profile", "pending", "accepted", "declined"],
      default: "local_profile",
      index: true,
    },
    invitationToken: { type: String, default: "", index: true },
    invitedUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
      index: true,
    },
    invitedAt: { type: Date, default: null },
    acceptedAt: { type: Date, default: null },
    declinedAt: { type: Date, default: null },
    connectionStatus: {
      type: String,
      enum: ["local_profile", "pending", "connected", "declined", "removed"],
      default: "local_profile",
      index: true,
    },
    permissions: {
      canViewScans: { type: Boolean, default: true },
      canShareRecommendations: { type: Boolean, default: true },
      canManageOwnPreferences: { type: Boolean, default: true },
      primaryCanManagePreferences: { type: Boolean, default: true },
    },
    lastActiveAt: { type: Date, default: null },
  },
  { timestamps: true }
);

const FamilyMember = mongoose.model("FamilyMember", familyMemberSchema);







const preferenceFields = {
  allergens: [{ type: String }],
  customAllergens: [{ type: String }],
  allergenImportance: { type: String, default: "Essential" },

  additives: [{ type: String }],
  customAdditives: [{ type: String }],
  additiveImportance: { type: String, default: "Essential" },

  diets: [{ type: String }],
  customDiets: [{ type: String }],
  dietImportance: { type: String, default: "Essential" },

  ingredients: [{ type: String }],
  customIngredients: [{ type: String }],
  ingredientImportance: { type: String, default: "Essential" },

  nutritions: [{ type: String }],
  customNutritions: [{ type: String }],
  nutritionImportance: { type: String, default: "Preferred" },

  healthConditions: [{ type: String }],
  customHealthConditions: [{ type: String }],
  healthConditionImportance: { type: String, default: "Essential" },

  avoidedIngredients: [{ type: String }],
  customAvoidedIngredients: [{ type: String }],
  avoidedIngredientImportance: { type: String, default: "Essential" },

  preferredIngredients: [{ type: String }],
  customPreferredIngredients: [{ type: String }],
  preferredIngredientImportance: { type: String, default: "Preferred" },

  productCategories: [{ type: String }],
  customProductCategories: [{ type: String }],
  productCategoryImportance: { type: String, default: "Preferred" },

  recommendationSettings: [{ type: String }],
  customRecommendationSettings: [{ type: String }],
  recommendationSettingImportance: { type: String, default: "Preferred" },
};

const primaryPreferenceSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
      index: true,
    },
    userName: { type: String, default: "Primary User" },
    preferenceOwnerType: { type: String, default: "primary" },
    ...preferenceFields,
  },
  { timestamps: true }
);

const familyPreferenceSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    userName: { type: String, default: "Primary User" },
    memberId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "FamilyMember",
      required: true,
      index: true,
    },
    memberName: { type: String, required: true },
    preferenceOwnerType: { type: String, default: "family" },
    memberUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
      index: true,
    },
    preferenceSource: {
      type: String,
      enum: ["primary_user", "family_member", "system"],
      default: "primary_user",
    },
    updatedByUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
    ...preferenceFields,
  },
  { timestamps: true }
);

familyPreferenceSchema.index(
  { userId: 1, memberId: 1 },
  { unique: true, name: "userId_1_memberId_1" }
);

const PrimaryPreference = mongoose.model("PrimaryPreference", primaryPreferenceSchema);
const FamilyPreference = mongoose.model("FamilyPreference", familyPreferenceSchema);






const scanHistorySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    userName: { type: String, default: "" },
    userEmail: { type: String, default: "" },
    rawOcrText: { type: String, default: "" },
    ocrValidation: { type: mongoose.Schema.Types.Mixed, default: {} },
    ingredients: [{ type: String }],
    ingredientCount: { type: Number, default: 0 },
    ocrResultId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "OcrResult",
      default: null,
      index: true,
    },
    productAnalysisId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ProductAnalysis",
      default: null,
      index: true,
    },
    recommendationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ProductRecommendation",
      default: null,
      index: true,
    },
    healthReportId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "HealthReport",
      default: null,
      index: true,
    },
    productResult: { type: mongoose.Schema.Types.Mixed, default: {} },
    ingredientDetails: { type: mongoose.Schema.Types.Mixed, default: [] },
    healthInformation: { type: mongoose.Schema.Types.Mixed, default: {} },
    scanResult: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

scanHistorySchema.index({ userId: 1, createdAt: -1 });

const ScanHistory = mongoose.model("ScanHistory", scanHistorySchema);

const ocrResultSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    scanHistoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ScanHistory",
      default: null,
      index: true,
    },
    rawText: { type: String, default: "" },
    extractedIngredients: [{ type: String }],
    ingredientCount: { type: Number, default: 0 },
    validation: { type: mongoose.Schema.Types.Mixed, default: {} },
    scanResult: { type: mongoose.Schema.Types.Mixed, default: {} },
    source: { type: String, default: "mobile_ocr" },
  },
  { timestamps: true }
);

ocrResultSchema.index({ userId: 1, createdAt: -1 });

const OcrResult = mongoose.model("OcrResult", ocrResultSchema);


const productAnalysisSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    scanHistoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ScanHistory",
      default: null,
      index: true,
    },
    ocrResultId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "OcrResult",
      default: null,
      index: true,
    },
    recommendationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ProductRecommendation",
      default: null,
      index: true,
    },
    productName: { type: String, default: "Scanned Product" },
    rawOcrText: { type: String, default: "" },
    ingredients: [{ type: String }],
    productIdentification: { type: mongoose.Schema.Types.Mixed, default: {} },
    ingredientDetails: { type: mongoose.Schema.Types.Mixed, default: [] },
    allergens: { type: mongoose.Schema.Types.Mixed, default: {} },
    halal: { type: mongoose.Schema.Types.Mixed, default: {} },
    calories: { type: mongoose.Schema.Types.Mixed, default: {} },
    nutrition: { type: mongoose.Schema.Types.Mixed, default: {} },
    nutritionAnalysis: { type: mongoose.Schema.Types.Mixed, default: {} },
    safetySummary: { type: mongoose.Schema.Types.Mixed, default: {} },
    selectedPreferences: { type: mongoose.Schema.Types.Mixed, default: [] },
    suitability: { type: mongoose.Schema.Types.Mixed, default: {} },
    alternatives: { type: mongoose.Schema.Types.Mixed, default: [] },
    datasetMatch: { type: mongoose.Schema.Types.Mixed, default: null },
    healthInformation: { type: mongoose.Schema.Types.Mixed, default: {} },
    fullResponse: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

productAnalysisSchema.index({ userId: 1, createdAt: -1 });
productAnalysisSchema.index({ scanHistoryId: 1, createdAt: -1 });

const ProductAnalysis = mongoose.model("ProductAnalysis", productAnalysisSchema);





const productRecommendationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    scanHistoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ScanHistory",
      default: null,
      index: true,
    },
    productName: { type: String, default: "Scanned Product" },
    ingredients: [{ type: String }],
    scanResult: { type: mongoose.Schema.Types.Mixed, default: {} },
    results: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

productRecommendationSchema.index({ userId: 1, createdAt: -1 });

const ProductRecommendation = mongoose.model("ProductRecommendation", productRecommendationSchema);


const familyNotificationSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: [
        "family_invite",
        "family_invite_accepted",
        "family_invite_declined",
        "shared_product",
        "shared_recommendation",
        "shared_ingredient_warning",
        "shared_health_guide",
        "shared_nutrition_advice",
        "new_recommendation",
        "preference_update",
        "system",
      ],
      default: "system",
      index: true,
    },
    senderUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
      index: true,
    },
    senderName: { type: String, default: "" },
    recipientUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
      index: true,
    },
    recipientEmail: { type: String, default: "", lowercase: true, trim: true, index: true },
    memberId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "FamilyMember",
      default: null,
      index: true,
    },
    title: { type: String, default: "" },
    body: { type: String, default: "" },
    status: {
      type: String,
      enum: ["unread", "read", "archived"],
      default: "unread",
      index: true,
    },
    actionStatus: {
      type: String,
      enum: ["none", "pending", "accepted", "declined", "expired"],
      default: "none",
      index: true,
    },
    invitationToken: { type: String, default: "", index: true },
    payload: { type: mongoose.Schema.Types.Mixed, default: {} },
    delivery: { type: mongoose.Schema.Types.Mixed, default: {} },
    readAt: { type: Date, default: null },
    actedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

familyNotificationSchema.index({ recipientUserId: 1, createdAt: -1 });
familyNotificationSchema.index({ recipientEmail: 1, createdAt: -1 });

const FamilyNotification = mongoose.model("FamilyNotification", familyNotificationSchema);


const preferenceHistorySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    memberId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "FamilyMember",
      default: null,
      index: true,
    },
    preferenceId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
      index: true,
    },
    ownerType: {
      type: String,
      enum: ["primary", "family"],
      default: "primary",
      index: true,
    },
    version: { type: Number, default: 1, index: true },
    changeType: {
      type: String,
      enum: ["created", "updated", "deleted", "self_updated"],
      default: "updated",
      index: true,
    },
    changedByUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
      index: true,
    },
    preferencesSnapshot: { type: mongoose.Schema.Types.Mixed, default: {} },
    aiFeedback: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

preferenceHistorySchema.index({ userId: 1, memberId: 1, version: -1 });

const PreferenceHistory = mongoose.model("PreferenceHistory", preferenceHistorySchema);

const productComparisonHistorySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    scanHistoryIds: [{ type: mongoose.Schema.Types.ObjectId, ref: "ScanHistory" }],
    productA: { type: mongoose.Schema.Types.Mixed, default: {} },
    productB: { type: mongoose.Schema.Types.Mixed, default: {} },
    comparisonResult: { type: mongoose.Schema.Types.Mixed, default: {} },
    preferencesSnapshot: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

productComparisonHistorySchema.index({ userId: 1, createdAt: -1 });

const ProductComparisonHistory = mongoose.model(
  "ProductComparisonHistory",
  productComparisonHistorySchema
);

const sharedContentSchema = new mongoose.Schema(
  {
    senderUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    senderName: { type: String, default: "" },
    recipientUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
      index: true,
    },
    recipientEmail: { type: String, default: "", lowercase: true, trim: true, index: true },
    memberId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "FamilyMember",
      default: null,
      index: true,
    },
    type: {
      type: String,
      enum: ["product", "recommendation", "ingredient_warning", "nutrition_advice", "health_guide"],
      default: "product",
      index: true,
    },
    title: { type: String, default: "" },
    message: { type: String, default: "" },
    payload: { type: mongoose.Schema.Types.Mixed, default: {} },
    status: {
      type: String,
      enum: ["sent", "read", "archived"],
      default: "sent",
      index: true,
    },
    notificationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "FamilyNotification",
      default: null,
      index: true,
    },
  },
  { timestamps: true }
);

sharedContentSchema.index({ senderUserId: 1, createdAt: -1 });
sharedContentSchema.index({ recipientUserId: 1, createdAt: -1 });

const SharedContent = mongoose.model("SharedContent", sharedContentSchema);

const productFeedbackSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    scanHistoryId: { type: mongoose.Schema.Types.ObjectId, ref: "ScanHistory", default: null, index: true },
    productAnalysisId: { type: mongoose.Schema.Types.ObjectId, ref: "ProductAnalysis", default: null, index: true },
    productName: { type: String, default: "" },
    rating: { type: Number, default: null },
    feedbackType: { type: String, default: "general", index: true },
    message: { type: String, default: "" },
    payload: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

productFeedbackSchema.index({ userId: 1, createdAt: -1 });

const ProductFeedback = mongoose.model("ProductFeedback", productFeedbackSchema);

const healthReportSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    scanHistoryId: { type: mongoose.Schema.Types.ObjectId, ref: "ScanHistory", default: null, index: true },
    productAnalysisId: { type: mongoose.Schema.Types.ObjectId, ref: "ProductAnalysis", default: null, index: true },
    recommendationId: { type: mongoose.Schema.Types.ObjectId, ref: "ProductRecommendation", default: null, index: true },
    productName: { type: String, default: "" },
    reportType: { type: String, default: "scan_analysis", index: true },
    safetyScore: { type: Number, default: null },
    halal: { type: mongoose.Schema.Types.Mixed, default: {} },
    calories: { type: mongoose.Schema.Types.Mixed, default: {} },
    ingredientBreakdown: { type: mongoose.Schema.Types.Mixed, default: [] },
    healthInformation: { type: mongoose.Schema.Types.Mixed, default: {} },
    recommendation: { type: mongoose.Schema.Types.Mixed, default: {} },
    fullReport: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

healthReportSchema.index({ userId: 1, createdAt: -1 });

const HealthReport = mongoose.model("HealthReport", healthReportSchema);

const activityLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
      index: true,
    },
    action: { type: String, required: true, index: true },
    entityType: { type: String, default: "", index: true },
    entityId: { type: mongoose.Schema.Types.ObjectId, default: null, index: true },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

activityLogSchema.index({ userId: 1, createdAt: -1 });

const ActivityLog = mongoose.model("ActivityLog", activityLogSchema);

const logActivity = async ({ userId = null, action, entityType = "", entityId = null, metadata = {} }) => {
  try {
    await ActivityLog.create({
      userId: isValidObjectId(userId) ? userId : null,
      action,
      entityType,
      entityId: isValidObjectId(entityId) ? entityId : null,
      metadata,
    });
  } catch (error) {
    console.warn("Activity log failed:", error.message);
  }
};


async function fixPreferenceIndexes() {
  try {
    await PrimaryPreference.collection.createIndex(
      { userId: 1 },
      { unique: true, name: "primary_userId_1" }
    );

    await FamilyPreference.collection.createIndex(
      { userId: 1, memberId: 1 },
      { unique: true, name: "userId_1_memberId_1" }
    );

    const oldCollections = await mongoose.connection.db.listCollections({ name: "preferences" }).toArray();
    if (oldCollections.length > 0) {
      const oldPreferenceCollection = mongoose.connection.db.collection("preferences");
      const indexes = await oldPreferenceCollection.indexes();
      for (const idx of indexes) {
        const isWrongUniqueUserIndex =
          idx.unique === true &&
          JSON.stringify(idx.key) === JSON.stringify({ userId: 1 });

        if (isWrongUniqueUserIndex) {
          await oldPreferenceCollection.dropIndex(idx.name);
          console.log(`Dropped old wrong unique index from preferences: ${idx.name}`);
        }
      }
    }

    console.log("Preference indexes fixed successfully");
  } catch (error) {
    console.error("Preference index fix error:", error.message);
  }
}





const auth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ message: "No token provided" });
    }

    next();
  } catch (error) {
    res.status(401).json({ message: "Invalid token", error: error.message });
  }
};




const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

const toStringArray = (value) => {
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item).trim()).filter(Boolean);
};

const numberOrDefault = (value, defaultValue = 1) => {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? n : defaultValue;
};

const normalizeEmail = (value) => String(value || "").trim().toLowerCase();

const isValidEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizeEmail(value));

const isValidPassword = (value) =>
  typeof value === "string" &&
  value.length >= 6 &&
  /[A-Za-z]/.test(value) &&
  /[0-9]/.test(value);

const sanitizeUser = (user) => {
  const source = typeof user.toObject === "function" ? user.toObject() : { ...user };
  delete source.password;
  delete source.passwordResetTokenHash;
  delete source.passwordResetExpiresAt;
  delete source.passwordResetUsedAt;
  return source;
};

const buildToken = (prefix, userId) => `${prefix}-${userId}-${Date.now()}`;

const buildUserSession = async (user, message = "Login successful") => {
  await User.findByIdAndUpdate(user._id, { $set: { lastLoginAt: new Date() } });
  const familyMembers = await FamilyMember.find({ userId: user._id });
  const freshUser = await User.findById(user._id).lean();
  return {
    message,
    user: sanitizeUser(freshUser || user),
    hasFamilyMembers: familyMembers.length > 0,
    token: buildToken("dummy-token", user._id),
  };
};

const validSettingsPayload = (settings = {}) => ({
  emailNotifications: settings.emailNotifications !== false,
  familySharing: settings.familySharing !== false,
  saveScanHistory: settings.saveScanHistory !== false,
  recommendationAlerts: settings.recommendationAlerts !== false,
});

const hashResetToken = (token) =>
  crypto.createHash("sha256").update(String(token || "")).digest("hex");

const sendPasswordResetEmail = async ({ email, token, user }) => {
  const resetUrl = process.env.PASSWORD_RESET_WEB_URL
    ? `${process.env.PASSWORD_RESET_WEB_URL}?email=${encodeURIComponent(email)}&token=${encodeURIComponent(token)}`
    : "";
  const subject = "CalorieMate password reset code";
  const text = [
    `Hello ${user.fullName || "CalorieMate user"},`,
    "",
    `Your CalorieMate password reset code is: ${token}`,
    resetUrl ? `Reset link: ${resetUrl}` : "",
    "",
    "This code expires in 15 minutes. Ignore this email if you did not request a password reset.",
  ].filter(Boolean).join("\n");

  if (process.env.EMAIL_PROVIDER_WEBHOOK_URL) {
    await axios.post(
      process.env.EMAIL_PROVIDER_WEBHOOK_URL,
      {
        to: email,
        subject,
        text,
        payload: { userId: user._id, resetUrl },
      },
      { timeout: 8000 }
    );
    return { attempted: true, status: "sent", provider: "webhook" };
  }

  if (process.env.SMTP_HOST && nodemailer) {
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT || 587),
      secure: process.env.SMTP_SECURE === "true",
      auth: process.env.SMTP_USER
        ? {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS || "",
          }
        : undefined,
    });
    await transporter.sendMail({
      from: process.env.EMAIL_FROM || "CalorieMate <no-reply@caloriemate.local>",
      to: email,
      subject,
      text,
    });
    return { attempted: true, status: "sent", provider: "smtp" };
  }

  console.log(`Password reset token for ${email}: ${token}`);
  return {
    attempted: false,
    status: "not_configured",
    message: "Configure SMTP_HOST or EMAIL_PROVIDER_WEBHOOK_URL to send password reset emails.",
  };
};

const createInvitationToken = () =>
  `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 12)}`;

const sendInvitationEmail = async ({ recipientEmail, primaryUser, member }) => {
  if (!recipientEmail) {
    return { attempted: false, status: "not_requested", message: "No invitation email was provided." };
  }

  if (process.env.EMAIL_PROVIDER_WEBHOOK_URL) {
    try {
      const inviterName = primaryUser.fullName || primaryUser.email || "A CalorieMate user";
      await axios.post(
        process.env.EMAIL_PROVIDER_WEBHOOK_URL,
        {
          to: recipientEmail,
          subject: "CalorieMate family personalization request",
          text:
            `${inviterName} invited you to join their CalorieMate family profile for personalized food safety and nutrition preferences.`,
          html:
            `<p>${inviterName} invited you to join their CalorieMate family profile.</p>` +
            `<p>Open CalorieMate and check Family Requests to accept or decline the invitation.</p>`,
          payload: {
            primaryUserId: primaryUser._id,
            memberId: member._id,
            memberName: member.name,
            invitationToken: member.invitationToken,
          },
        },
        { timeout: 8000 }
      );
      return {
        attempted: true,
        status: "sent",
        provider: "webhook",
        message: "Email invitation was sent through the configured provider webhook.",
      };
    } catch (error) {
      return {
        attempted: true,
        status: "failed",
        provider: "webhook",
        message: error.message,
      };
    }
  }

  if (!process.env.SMTP_HOST) {
    return {
      attempted: false,
      status: "not_configured",
      message: "In-app notification saved. Configure SMTP_HOST or EMAIL_PROVIDER_WEBHOOK_URL to send email.",
    };
  }

  return {
    attempted: false,
    status: "smtp_not_integrated",
    message: "SMTP settings were found, but this build uses EMAIL_PROVIDER_WEBHOOK_URL for email delivery.",
  };
};

const createFamilyInviteNotification = async ({ primaryUser, member }) => {
  const recipientEmail = normalizeEmail(member.invitationEmail);
  const recipientUser = recipientEmail
    ? await User.findOne({ email: recipientEmail }).select("_id fullName email").lean()
    : null;
  const emailDelivery = await sendInvitationEmail({ recipientEmail, primaryUser, member });

  const notification = await FamilyNotification.create({
    type: "family_invite",
    senderUserId: primaryUser._id,
    senderName: primaryUser.fullName || primaryUser.email || "CalorieMate user",
    recipientUserId: recipientUser?._id || null,
    recipientEmail,
    memberId: member._id,
    title: "Family personalization request",
    body: `${primaryUser.fullName || primaryUser.email || "A CalorieMate user"} invited you to personalize your food safety profile.`,
    actionStatus: "pending",
    invitationToken: member.invitationToken,
    payload: {
      primaryUserId: primaryUser._id,
      primaryUserName: primaryUser.fullName || primaryUser.email || "Primary User",
      memberId: member._id,
      memberName: member.name,
      relation: member.relation,
      healthConditions: member.healthConditions,
    },
    delivery: {
      inApp: true,
      email: emailDelivery,
    },
  });

  if (recipientUser?._id) {
    await FamilyMember.findByIdAndUpdate(member._id, {
      $set: { invitedUserId: recipientUser._id },
    });
  }

  return notification;
};

const createAppNotification = async ({
  type = "system",
  senderUserId = null,
  senderName = "",
  recipientUserId = null,
  recipientEmail = "",
  memberId = null,
  title = "",
  body = "",
  actionStatus = "none",
  payload = {},
  delivery = { inApp: true },
}) => {
  try {
    return await FamilyNotification.create({
      type,
      senderUserId: isValidObjectId(senderUserId) ? senderUserId : null,
      senderName,
      recipientUserId: isValidObjectId(recipientUserId) ? recipientUserId : null,
      recipientEmail: normalizeEmail(recipientEmail),
      memberId: isValidObjectId(memberId) ? memberId : null,
      title,
      body,
      actionStatus,
      payload,
      delivery,
      status: "unread",
    });
  } catch (error) {
    console.warn("Notification create failed:", error.message);
    return null;
  }
};


const loadJsonData = (fileName, fallback = []) => {
  try {
    return JSON.parse(
      fs.readFileSync(path.join(__dirname, "data", fileName), "utf8")
    );
  } catch (error) {
    console.error(`Could not load Backend/data/${fileName}:`, error.message);
    return fallback;
  }
};

const foodProductsDataset = loadJsonData(
  "product_master_rebuilt.json",
  loadJsonData("products_cleaned.json")
);
const halalVerifiedProducts = loadJsonData(
  "pakistan_halal_products.json",
  loadJsonData("halal_verified_products.json")
);
const ingredientKnowledgeDataset = loadJsonData(
  "ingredient_master_refined.json",
  loadJsonData("ingredient_master.json")
);
const productRetriever = loadJsonData("product_retriever.json", {
  thresholds: { identified: 0.48, highConfidence: 0.72, minimumMargin: 0.06 },
  idf: {},
  products: [],
});

const normalizeMatchText = (value) =>
  String(value || "")
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

const splitDatasetIngredients = (product) => {
  const parsed = String(product.parsed_ingredients || "")
    .split("|")
    .map(normalizeMatchText)
    .filter(Boolean);

  if (parsed.length > 0) return [...new Set(parsed)];

  return splitIngredientsSmart(product.Ingredients || "")
    .map(normalizeMatchText)
    .filter(Boolean);
};

const ingredientAliases = (record) => [
  normalizeMatchText(record.name),
  ...toStringArray(record.aliases).map(normalizeMatchText),
  ...toStringArray(record.e_codes).map(normalizeMatchText),
].filter(Boolean);

const ingredientKnowledgeIndex = ingredientKnowledgeDataset.map((record) => ({
  ...record,
  __aliases: ingredientAliases(record),
}));

const findIngredientKnowledge = (ingredient) => {
  const clean = normalizeMatchText(ingredient);
  if (!clean) return null;

  const exact = ingredientKnowledgeIndex.find((record) =>
    record.__aliases.some((alias) => alias === clean)
  );
  if (exact) return exact;

  return ingredientKnowledgeIndex.find((record) =>
    record.__aliases.some((alias) => {
      const shorter = alias.length <= clean.length ? alias : clean;
      return shorter.length >= 7 && (clean.includes(alias) || alias.includes(clean));
    })
  ) || null;
};

const scoreProductIngredientMatch = (scannedIngredients, product) => {
  const productIngredients = splitDatasetIngredients(product);
  if (productIngredients.length === 0) return 0;

  let matched = 0;
  for (const scanned of scannedIngredients) {
    const cleanScanned = normalizeMatchText(scanned);
    if (
      productIngredients.some(
        (candidate) =>
          candidate === cleanScanned ||
          (candidate.length > 3 && cleanScanned.includes(candidate)) ||
          (cleanScanned.length > 3 && candidate.includes(cleanScanned))
      )
    ) {
      matched += 1;
    }
  }

  const precision = matched / Math.max(1, scannedIngredients.length);
  const coverage = matched / Math.max(1, productIngredients.length);
  return Number((precision * 0.75 + coverage * 0.25).toFixed(4));
};

const retrieverVector = (ingredients) => {
  const counts = {};
  normalizeMatchText(ingredients.join(" "))
    .split(" ")
    .filter(Boolean)
    .forEach((token) => {
      counts[token] = (counts[token] || 0) + 1;
    });
  const weighted = Object.fromEntries(
    Object.entries(counts).map(([token, count]) => [
      token,
      count * (productRetriever.idf[token] || 1),
    ])
  );
  const norm = Math.sqrt(
    Object.values(weighted).reduce((total, value) => total + value * value, 0)
  ) || 1;
  return Object.fromEntries(
    Object.entries(weighted).map(([token, value]) => [token, value / norm])
  );
};

const weightedVector = (ingredients, idf = {}) => {
  const counts = {};
  normalizeMatchText(ingredients.join(" "))
    .split(" ")
    .filter(Boolean)
    .forEach((token) => {
      counts[token] = (counts[token] || 0) + 1;
    });
  const weighted = Object.fromEntries(
    Object.entries(counts).map(([token, count]) => [token, count * (idf[token] || 1)])
  );
  const norm = Math.sqrt(
    Object.values(weighted).reduce((total, value) => total + value * value, 0)
  ) || 1;
  return Object.fromEntries(
    Object.entries(weighted).map(([token, value]) => [token, value / norm])
  );
};

const inferDatasetCategory = (ingredients) => {
  const model = productRetriever.categoryModel || {};
  const query = weightedVector(ingredients, model.idf);
  const best = (model.labels || [])
    .map((label) => ({
      ...label,
      score: Object.entries(query).reduce(
        (total, [token, value]) => total + value * (label.vector[token] || 0),
        0
      ),
    }))
    .sort((a, b) => b.score - a.score)[0];
  if (!best || best.score < (model.minimumConfidence || 0.12)) return null;
  return {
    Category: best.category,
    "Sub Category": best.subCategory,
    product_key: "",
    categoryInferenceConfidence: Number(best.score.toFixed(4)),
  };
};

const identifyDatasetProduct = (ingredients) => {
  const query = retrieverVector(ingredients);
  const ranked = productRetriever.products
    .map((candidate) => ({
      candidate,
      score: Object.entries(query).reduce(
        (total, [token, value]) => total + value * (candidate.vector[token] || 0),
        0
      ),
    }))
    .sort((a, b) => b.score - a.score);
  const best = ranked[0];
  const margin = best ? best.score - (ranked[1]?.score || 0) : 0;
  const thresholds = productRetriever.thresholds;
  const confident =
    best &&
    best.score >= thresholds.identified &&
    margin >= thresholds.minimumMargin;
  const closestProduct = best
    ? foodProductsDataset.find((product) => product.product_key === best.candidate.productKey)
    : null;
  const inferredCategory = inferDatasetCategory(ingredients);
  const categoryMismatch =
    inferredCategory &&
    closestProduct &&
    best.score < thresholds.highConfidence &&
    inferredCategory.categoryInferenceConfidence >= 0.18 &&
    (
      normalizeMatchText(inferredCategory.Category) !== normalizeMatchText(closestProduct.Category) ||
      normalizeMatchText(inferredCategory["Sub Category"]) !==
        normalizeMatchText(closestProduct["Sub Category"])
    );
  const categoryProduct = inferredCategory || closestProduct;
  const bestProduct = confident && !categoryMismatch ? closestProduct : null;

  if (!confident || !bestProduct) {
    return {
      identified: false,
      confidence: Number((best?.score || 0).toFixed(4)),
      confidenceLevel: "Low",
      matchMargin: Number(margin.toFixed(4)),
      productName: "Unknown scanned product",
      product: null,
      categoryProduct,
      explanation: categoryMismatch
        ? "Product name was withheld because category evidence disagreed with the closest product match."
        : "No trusted dataset product matched with enough confidence.",
    };
  }

  return {
    identified: true,
    confidence: Number(best.score.toFixed(4)),
    confidenceLevel: best.score >= thresholds.highConfidence ? "High" : "Moderate",
    matchMargin: Number(margin.toFixed(4)),
    productName: best.candidate.productName,
    product: bestProduct,
    categoryProduct: bestProduct,
    explanation: "Matched by the trained ingredient-signature retriever.",
  };
};

const roundNumber = (value, digits = 1) => {
  if (!Number.isFinite(value)) return null;
  return Number(value.toFixed(digits));
};

const parseNutritionFacts = (nutritionText) => {
  const rawText = String(nutritionText || "").trim();
  const text = rawText.replace(/\s+/g, " ");
  const basisMatch = text.match(/per\s*(\d+(?:\.\d+)?)\s*(g|gram|grams|ml|millilitre|milliliter)s?/i);
  const basisAmount = basisMatch ? Number(basisMatch[1]) : 100;
  const basisUnit = basisMatch
    ? (basisMatch[2].toLowerCase().startsWith("m") ? "ml" : "g")
    : "g";
  const scale = basisAmount > 0 ? 100 / basisAmount : 1;

  const readNutrient = (labels, units = "g|mg|kcal|kj") => {
    for (const label of labels) {
      const pattern = new RegExp(
        `(?:^|[;,:\\s])${label}\\s*[:\\-]?\\s*(?:~|≈|about)?\\s*(\\d+(?:\\.\\d+)?)\\s*(${units})?`,
        "i"
      );
      const match = text.match(pattern);
      if (match) {
        return { value: Number(match[1]), unit: (match[2] || "").toLowerCase() };
      }
    }
    return null;
  };

  const readGramPer100 = (labels) => {
    const item = readNutrient(labels, "g|mg");
    if (!item) return null;
    const valueInGram = item.unit === "mg" ? item.value / 1000 : item.value;
    return roundNumber(valueInGram * scale, 2);
  };

  const readMgPer100 = (labels) => {
    const item = readNutrient(labels, "mg|g");
    if (!item) return null;
    const valueInMg = item.unit === "g" ? item.value * 1000 : item.value;
    return roundNumber(valueInMg * scale, 1);
  };

  const energy = readNutrient(["energy", "calories", "calorie"], "kcal|kj|cal");
  const fatGPer100 = readGramPer100(["total\\s+fat", "fat"]);
  const carbohydrateGPer100 = readGramPer100(["carbohydrates?", "carbs?"]);
  const proteinGPer100 = readGramPer100(["protein"]);
  const sugarsGPer100 = readGramPer100(["sugars?", "total\\s+sugars?"]);
  const saturatedFatGPer100 = readGramPer100(["saturated\\s+fat", "saturates?", "sat\\.?\\s*fat"]);
  const fiberGPer100 = readGramPer100(["dietary\\s+fiber", "fibre", "fiber"]);
  const saltGPer100 = readGramPer100(["salt"]);
  const sodiumMgPer100 = readMgPer100(["sodium"]) ??
    (saltGPer100 == null ? null : roundNumber(saltGPer100 * 400, 1));

  let caloriesPer100 = null;
  let caloriesMethod = "Calories unavailable because no usable nutrition values were found.";
  let confidence = 0;

  if (energy) {
    const kcal = energy.unit === "kj" ? energy.value / 4.184 : energy.value;
    caloriesPer100 = roundNumber(kcal * scale, 1);
    caloriesMethod = basisAmount === 100
      ? "Declared energy from nutrition facts"
      : `Declared energy normalized from per ${basisAmount} ${basisUnit}`;
    confidence = 0.92;
  } else if (fatGPer100 || carbohydrateGPer100 || proteinGPer100) {
    caloriesPer100 = roundNumber(
      (carbohydrateGPer100 || 0) * 4 + (proteinGPer100 || 0) * 4 + (fatGPer100 || 0) * 9,
      1
    );
    caloriesMethod = "Estimated from carbohydrate, protein, and fat.";
    confidence = 0.72;
  }

  return {
    available: caloriesPer100 !== null ||
      fatGPer100 !== null ||
      carbohydrateGPer100 !== null ||
      proteinGPer100 !== null ||
      sugarsGPer100 !== null ||
      sodiumMgPer100 !== null,
    caloriesPer100,
    unit: basisUnit,
    basisAmount,
    basisUnit,
    servingBasis: basisMatch ? `per ${basisAmount} ${basisUnit}` : "assumed per 100 g",
    method: caloriesMethod,
    confidence,
    fatGPer100,
    saturatedFatGPer100,
    carbohydrateGPer100,
    sugarsGPer100,
    proteinGPer100,
    fiberGPer100,
    sodiumMgPer100,
    saltGPer100,
    raw: rawText,
  };
};

const extractCaloriesFromNutrition = (nutritionText) => {
  const nutrition = parseNutritionFacts(nutritionText);
  return {
    caloriesPer100: nutrition.caloriesPer100,
    method: nutrition.method,
    confidence: nutrition.confidence,
    source: nutrition.available ? "Nutrition facts" : "Unavailable",
  };
};

const getProductNutrition = (product) => {
  if (!product) return parseNutritionFacts("");
  if (product.nutrition_parsed && product.nutrition_parsed.available) {
    return {
      ...parseNutritionFacts(product["Nutritional Facts"] || ""),
      ...product.nutrition_parsed,
      source: "Matched dataset product",
    };
  }
  return {
    ...parseNutritionFacts(product["Nutritional Facts"] || ""),
    source: "Matched dataset product",
  };
};

const averageNutritionValues = (items) => {
  const keys = [
    "caloriesPer100",
    "fatGPer100",
    "saturatedFatGPer100",
    "carbohydrateGPer100",
    "sugarsGPer100",
    "proteinGPer100",
    "fiberGPer100",
    "sodiumMgPer100",
    "saltGPer100",
  ];
  const averages = { available: false };
  for (const key of keys) {
    const values = items
      .map((item) => item[key])
      .filter((value) => typeof value === "number" && Number.isFinite(value));
    if (values.length > 0) {
      averages[key] = roundNumber(values.reduce((sum, value) => sum + value, 0) / values.length, 1);
      averages.available = true;
    }
  }
  return averages;
};

const categoryNutritionAverages = (() => {
  const groups = new Map();
  for (const product of halalVerifiedProducts) {
    const nutrition = getProductNutrition(product);
    if (!nutrition.available) continue;
    const category = normalizeMatchText(product.Category);
    const subCategory = normalizeMatchText(product["Sub Category"]);
    for (const key of [`category:${category}`, `subcategory:${category}:${subCategory}`]) {
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push(nutrition);
    }
  }
  const averages = new Map();
  for (const [key, items] of groups.entries()) {
    averages.set(key, averageNutritionValues(items));
  }
  return averages;
})();

const resolveNutritionForAnalysis = ({ scannedNutritionText, matchedProduct, categoryProduct }) => {
  const scannedNutrition = parseNutritionFacts(scannedNutritionText);
  if (scannedNutrition.available) {
    return {
      ...scannedNutrition,
      source: "Scanned nutrition label",
      estimated: false,
      confidence: Math.max(scannedNutrition.confidence, 0.9),
    };
  }

  const matchedNutrition = getProductNutrition(matchedProduct);
  if (matchedNutrition.available) {
    return {
      ...matchedNutrition,
      source: "Matched dataset product",
      estimated: false,
    };
  }

  const category = normalizeMatchText(categoryProduct?.Category);
  const subCategory = normalizeMatchText(categoryProduct?.["Sub Category"]);
  const average =
    categoryNutritionAverages.get(`subcategory:${category}:${subCategory}`) ||
    categoryNutritionAverages.get(`category:${category}`);
  if (average?.available) {
    return {
      ...average,
      unit: "g/ml",
      basisAmount: 100,
      basisUnit: "g/ml",
      servingBasis: "per 100 g/ml",
      method: "Estimated from same-category dataset average.",
      source: "Same-category average",
      estimated: true,
      confidence: 0.58,
    };
  }

  return {
    ...parseNutritionFacts(""),
    source: "Unavailable",
    estimated: false,
  };
};

const detectAllergensFromKnowledge = (ingredients) => {
  const groups = {
    milk: ["milk", "lactose", "whey", "casein", "butter", "cream", "ghee"],
    gluten: ["wheat", "gluten", "atta", "semolina", "barley", "rye", "malt"],
    nuts: ["almond", "cashew", "walnut", "pistachio", "hazelnut", "tree nuts"],
    peanuts: ["peanut", "groundnut"],
    soy: ["soy", "soya", "soybean", "soy lecithin"],
    egg: ["egg", "albumen"],
    fish: ["fish", "anchovy", "tuna", "salmon"],
    shellfish: ["shrimp", "prawn", "crab", "lobster", "shellfish"],
    sesame: ["sesame", "til", "tahini"],
  };

  const combined = ingredients.map(normalizeMatchText).join(" ");
  return Object.entries(groups)
    .filter(([, aliases]) => aliases.some((alias) => combined.includes(alias)))
    .map(([allergen, aliases]) => ({
      allergen,
      triggers: aliases.filter((alias) => combined.includes(alias)),
    }));
};

const plainSafetyStatus = (value) => {
  const clean = normalizeMatchText(value);
  if (["harmful", "restricted", "red", "not recommended"].some((x) => clean.includes(x))) {
    return "Harmful";
  }
  if (["moderate", "yellow", "caution", "limit", "unreviewed"].some((x) => clean.includes(x))) {
    return "Moderate";
  }
  return "Safe";
};

const HALAL_SAFE_TERMS = [
  "water", "sugar", "salt", "wheat", "flour", "rice", "corn", "maize",
  "oat", "barley", "cocoa", "chocolate", "milk", "cream", "butter", "cheese",
  "yogurt", "vegetable oil", "palm oil", "sunflower oil", "canola oil",
  "soybean oil", "olive oil", "fruit", "spice", "herb", "yeast", "baking soda",
  "sodium bicarbonate", "citric acid", "palm", "leavening", "raising agent",
  "egg", "malt", "whey", "skimmed milk", "whole milk", "lactose", "cereal",
  "starch", "corn starch", "potato starch", "cocoa powder", "vanilla", "honey",
  "almond", "peanut", "sesame", "soy", "soya", "lecithin", "fish",
];

const HARAM_HALAL_TERMS = [
  ["pork", "Pork is explicitly haram."],
  ["porcine", "Porcine source means pork-derived ingredient."],
  ["lard", "Lard is pork fat."],
  ["bacon", "Bacon is pork-derived."],
  ["ham", "Ham is pork-derived."],
  ["wine", "Wine/alcohol is not halal."],
  ["rum", "Rum/alcohol is not halal."],
  ["beer", "Beer/alcohol is not halal."],
  ["brandy", "Brandy/alcohol is not halal."],
  ["whisky", "Whisky/alcohol is not halal."],
  ["whiskey", "Whiskey/alcohol is not halal."],
  ["vodka", "Vodka/alcohol is not halal."],
  ["ethanol", "Ethanol/alcohol source requires rejection unless clearly processing residual within certified limits."],
  ["ethyl alcohol", "Ethyl alcohol is an alcohol-derived ingredient."],
  ["cochineal", "Cochineal/carmine is insect-derived and commonly treated as non-halal."],
  ["carmine", "Carmine is insect-derived and commonly treated as non-halal."],
];

const SOURCE_SENSITIVE_HALAL_TERMS = [
  ["gelatin", "Gelatin must have a halal-certified source."],
  ["gelatine", "Gelatine must have a halal-certified source."],
  ["collagen", "Collagen source must be verified."],
  ["rennet", "Rennet source must be halal-certified."],
  ["enzyme", "Enzyme source should be verified when not clearly microbial or plant-based."],
  ["enzymes", "Enzyme source should be verified when not clearly microbial or plant-based."],
  ["mono and diglycerides", "Mono- and diglycerides can be plant or animal derived."],
  ["monoglyceride", "Monoglycerides can be plant or animal derived."],
  ["diglyceride", "Diglycerides can be plant or animal derived."],
  ["glycerin", "Glycerin/glycerol source can be plant or animal derived."],
  ["glycerol", "Glycerol source can be plant or animal derived."],
  ["shortening", "Shortening source can be animal or vegetable."],
  ["animal fat", "Animal fat source must be verified."],
  ["animal rennet", "Animal rennet must be halal-certified."],
  ["shellac", "Shellac source should be verified for halal suitability."],
  ["l-cysteine", "L-cysteine source should be verified."],
];

const HALAL_E_CODES = new Map([
  ["e100", "Curcumin is plant-derived."],
  ["e101", "Riboflavin is generally halal."],
  ["e140", "Chlorophyll is plant-derived."],
  ["e150a", "Plain caramel colour is generally halal."],
  ["e150b", "Caramel colour is generally halal when not alcohol-carried."],
  ["e150c", "Caramel colour is generally halal when not alcohol-carried."],
  ["e150d", "Caramel IV colour is generally halal when used within permitted limits."],
  ["e160a", "Carotenes are generally plant-derived."],
  ["e160b", "Annatto is plant-derived."],
  ["e162", "Beetroot red is plant-derived."],
  ["e202", "Potassium sorbate is generally halal."],
  ["e211", "Sodium benzoate is generally halal."],
  ["e260", "Acetic acid is generally halal when not from intoxicating alcohol."],
  ["e296", "Malic acid is generally halal."],
  ["e300", "Ascorbic acid is generally halal."],
  ["e322", "Lecithin is generally halal when soy/sunflower/plant source is used."],
  ["e330", "Citric acid is generally halal."],
  ["e331", "Sodium citrates are generally halal."],
  ["e338", "Phosphoric acid is generally halal."],
  ["e407", "Carrageenan is seaweed-derived."],
  ["e412", "Guar gum is plant-derived."],
  ["e415", "Xanthan gum is generally halal."],
  ["e440", "Pectin is plant-derived."],
  ["e500", "Sodium carbonates are mineral/synthetic."],
  ["e501", "Potassium carbonates are mineral/synthetic."],
  ["e503", "Ammonium carbonates are mineral/synthetic."],
  ["e621", "MSG is generally halal."],
]);

const SOURCE_SENSITIVE_E_CODES = new Map([
  ["e304", "Ascorbyl palmitate source should be verified."],
  ["e422", "Glycerol can be plant or animal derived."],
  ["e431", "Polysorbate source should be verified."],
  ["e432", "Polysorbate source should be verified."],
  ["e433", "Polysorbate source should be verified."],
  ["e434", "Polysorbate source should be verified."],
  ["e435", "Polysorbate source should be verified."],
  ["e436", "Polysorbate source should be verified."],
  ["e441", "Gelatin must be halal-certified."],
  ["e470", "Fatty-acid salts can be plant or animal derived."],
  ["e471", "Mono- and diglycerides can be plant or animal derived."],
  ["e472", "Fatty-acid esters can be plant or animal derived."],
  ["e472a", "Fatty-acid esters can be plant or animal derived."],
  ["e472b", "Fatty-acid esters can be plant or animal derived."],
  ["e472c", "Fatty-acid esters can be plant or animal derived."],
  ["e472e", "Fatty-acid esters can be plant or animal derived."],
  ["e481", "Stearoyl lactylates can be plant or animal derived."],
  ["e482", "Stearoyl lactylates can be plant or animal derived."],
  ["e542", "Bone phosphate source must be verified."],
  ["e904", "Shellac source should be halal-verified."],
  ["e920", "L-cysteine source must be verified."],
]);

const HARAM_E_CODES = new Map([
  ["e120", "Carmine/cochineal is insect-derived and commonly treated as non-halal."],
]);

const extractEcodesFromText = (value) => {
  const text = String(value || "");
  const matches = [...text.matchAll(/\b(?:e|ins)\s*[-:]?\s*(\d{3}[a-z]?)\b/gi)];
  return [...new Set(matches.map((match) => `e${match[1].toLowerCase()}`))];
};

const escapeRegExp = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const termInNormalizedText = (clean, term) => {
  const normalizedTerm = normalizeMatchText(term);
  if (!clean || !normalizedTerm) return false;
  const pattern = normalizedTerm
    .split(/\s+/)
    .map(escapeRegExp)
    .join("\\s+");
  return new RegExp(`(^|\\s)${pattern}(\\s|$)`, "i").test(clean);
};

const hasAnyTerm = (clean, terms) =>
  terms.find(([term]) => termInNormalizedText(clean, term));

const sourceResolvedAsHalal = (clean) =>
  [
    "vegetable", "plant", "soy", "soya", "sunflower", "microbial", "synthetic",
    "fish gelatin", "fish gelatine", "halal certified", "halal-certified",
  ].some((term) => clean.includes(normalizeMatchText(term)));

const clearlyHalalIngredient = (ingredient) => {
  const clean = normalizeMatchText(ingredient);
  return HALAL_SAFE_TERMS.some((item) => clean === item || clean.includes(item));
};

const classifyIngredientHalal = (ingredient, record = null) => {
  const aliases = [
    ingredient,
    record?.name,
    ...(record?.aliases || []),
    ...(record?.e_codes || []),
  ].filter(Boolean);
  const clean = normalizeMatchText(aliases.join(" "));
  const eCodes = [
    ...extractEcodesFromText(ingredient),
    ...extractEcodesFromText(record?.name || ""),
    ...toStringArray(record?.e_codes).map((code) => normalizeMatchText(code).replace(/^ins/, "e")),
  ].filter(Boolean);
  const uniqueEcodes = [...new Set(eCodes)];

  const haramTerm = hasAnyTerm(clean, HARAM_HALAL_TERMS);
  if (haramTerm) {
    return {
      status: "Haram",
      confidence: 0.98,
      reason: haramTerm[1],
      eCodes: uniqueEcodes,
      sourceSensitive: false,
      matchedTriggers: [haramTerm[0]],
    };
  }

  const haramCode = uniqueEcodes.find((code) => HARAM_E_CODES.has(code));
  if (haramCode) {
    return {
      status: "Haram",
      confidence: 0.9,
      reason: HARAM_E_CODES.get(haramCode),
      eCodes: uniqueEcodes,
      sourceSensitive: false,
      matchedTriggers: [haramCode.toUpperCase()],
    };
  }

  const sensitiveTerm = hasAnyTerm(clean, SOURCE_SENSITIVE_HALAL_TERMS);
  const sensitiveCode = uniqueEcodes.find((code) => SOURCE_SENSITIVE_E_CODES.has(code));
  if (sensitiveTerm || sensitiveCode) {
    if (sourceResolvedAsHalal(clean)) {
      return {
        status: "Halal",
        confidence: 0.78,
        reason: `${sensitiveTerm?.[1] || SOURCE_SENSITIVE_E_CODES.get(sensitiveCode)} Source appears halal or plant/microbial based from the label text.`,
        eCodes: uniqueEcodes,
        sourceSensitive: true,
        matchedTriggers: [sensitiveTerm?.[0], sensitiveCode?.toUpperCase()].filter(Boolean),
      };
    }
    return {
      status: "Doubtful",
      confidence: 0.72,
      reason: sensitiveTerm?.[1] || SOURCE_SENSITIVE_E_CODES.get(sensitiveCode),
      eCodes: uniqueEcodes,
      sourceSensitive: true,
      matchedTriggers: [sensitiveTerm?.[0], sensitiveCode?.toUpperCase()].filter(Boolean),
    };
  }

  const halalCode = uniqueEcodes.find((code) => HALAL_E_CODES.has(code));
  if (halalCode) {
    return {
      status: "Halal",
      confidence: 0.86,
      reason: HALAL_E_CODES.get(halalCode),
      eCodes: uniqueEcodes,
      sourceSensitive: false,
      matchedTriggers: [halalCode.toUpperCase()],
    };
  }

  const recordHalalStatus = normalizeMatchText(record?.halal_status);
  if (recordHalalStatus === "halal") {
    return {
      status: "Halal",
      confidence: 0.84,
      reason: "Ingredient knowledge base marks this ingredient as halal.",
      eCodes: uniqueEcodes,
      sourceSensitive: false,
      matchedTriggers: [],
    };
  }
  if (recordHalalStatus === "haram") {
    return {
      status: "Haram",
      confidence: 0.92,
      reason: "Ingredient knowledge base marks this ingredient as haram.",
      eCodes: uniqueEcodes,
      sourceSensitive: false,
      matchedTriggers: [],
    };
  }

  if (clearlyHalalIngredient(ingredient) || record) {
    return {
      status: "Halal",
      confidence: record ? 0.76 : 0.7,
      reason: "No haram or source-sensitive marker was found for this common food ingredient.",
      eCodes: uniqueEcodes,
      sourceSensitive: false,
      matchedTriggers: [],
    };
  }

  return {
    status: "Halal",
    confidence: 0.62,
    reason: "No explicit haram or doubtful source marker was detected. Verify the physical label if certification is required.",
    eCodes: uniqueEcodes,
    sourceSensitive: false,
    matchedTriggers: [],
  };
};

const plainIngredientSummary = (record, ingredient) => {
  if (!record) {
    const halal = classifyIngredientHalal(ingredient);
    return halal.status === "Halal"
      ? "A commonly used food ingredient. No specific safety warning was found."
      : "This ingredient needs source verification before it can be treated as fully suitable.";
  }
  const purpose = String(record.purpose || "").replace(/\.$/, "");
  const effect = toStringArray(record.health_effects)[0] || "";
  return [purpose && `Used as ${purpose.toLowerCase()}.`, effect].filter(Boolean).join(" ");
};

const buildIngredientDetails = (ingredients) =>
  ingredients.map((ingredient) => {
    const record = findIngredientKnowledge(ingredient);
    const halal = classifyIngredientHalal(ingredient, record);
    if (!record) {
      return {
        scannedName: ingredient,
        name: ingredient,
        category: "Food Ingredient",
        purpose: "Used as part of the product recipe.",
        simpleExplanation: plainIngredientSummary(null, ingredient),
        safetyStatus: "Moderate",
        safetyReason: "Detailed reviewed safety information is not yet available, so use normal dietary caution.",
        healthEffects: [],
        halalStatus: halal.status,
        halalConfidence: halal.confidence,
        halalReason: halal.reason,
        halalSourceSensitive: halal.sourceSensitive,
        halalTriggers: halal.matchedTriggers,
        compliance: {},
        authorityNotes: [],
        eCodes: halal.eCodes.map((code) => code.toUpperCase()),
      };
    }

    return {
      scannedName: ingredient,
      name: record.name,
      category: record.category,
      purpose: record.purpose,
      simpleExplanation: plainIngredientSummary(record, ingredient),
      safetyStatus: plainSafetyStatus(record.safety_status),
      safetyReason: toStringArray(record.health_effects)[0] || "No major warning when used within permitted limits.",
      healthEffects: record.health_effects || [],
      halalStatus: halal.status,
      halalConfidence: halal.confidence,
      halalReason: halal.reason,
      halalSourceSensitive: halal.sourceSensitive,
      halalTriggers: halal.matchedTriggers,
      compliance: {},
      authorityNotes: [],
      eCodes: halal.eCodes.length > 0 ? halal.eCodes.map((code) => code.toUpperCase()) : record.e_codes || [],
      sources: record.sources || [],
    };
  });

const calculateHalalSummary = (details) => {
  const safeDetails = Array.isArray(details) ? details : [];
  const haram = safeDetails.filter((item) => normalizeMatchText(item.halalStatus) === "haram");
  const doubtful = safeDetails.filter(
    (item) =>
      normalizeMatchText(item.halalStatus) === "doubtful" ||
      normalizeMatchText(item.halalStatus).includes("certification")
  );
  const confidenceValues = safeDetails
    .map((item) => Number(item.halalConfidence))
    .filter((value) => Number.isFinite(value) && value > 0);
  const averageConfidence = confidenceValues.length > 0
    ? confidenceValues.reduce((sum, value) => sum + value, 0) / confidenceValues.length
    : 0.76;

  if (haram.length > 0) {
    return {
      status: "Haram",
      confidence: Math.max(0.9, ...haram.map((item) => Number(item.halalConfidence) || 0)),
      reasons: haram.map((item) => `${item.name} is haram: ${item.halalReason || "a haram marker was detected."}`),
      ingredientFlags: haram.map((item) => ({
        name: item.name,
        status: item.halalStatus,
        reason: item.halalReason || "",
        triggers: item.halalTriggers || [],
      })),
      classificationMethod: "Ingredient-level halal trigger analysis",
    };
  }
  if (doubtful.length > 0) {
    return {
      status: "Doubtful",
      confidence: Math.max(0.65, Math.min(0.82, averageConfidence)),
      reasons: doubtful.map((item) => `${item.name} needs verification: ${item.halalReason || "source details are not clear."}`),
      ingredientFlags: doubtful.map((item) => ({
        name: item.name,
        status: item.halalStatus,
        reason: item.halalReason || "",
        triggers: item.halalTriggers || [],
      })),
      classificationMethod: "Source-sensitive ingredient and additive analysis",
    };
  }
  return {
    status: "Halal",
    confidence: Math.max(0.72, Math.min(0.94, averageConfidence)),
    reasons: ["No haram or unresolved source-sensitive ingredient was detected."],
    ingredientFlags: [],
    classificationMethod: "Ingredient and additive rule analysis",
  };
};

const resolveProductHalalSummary = (product, details) => {
  const ingredientSummary = calculateHalalSummary(details);
  if (ingredientSummary.status === "Haram") return ingredientSummary;

  if (!product?.halal_status) return ingredientSummary;

  const productStatus = normalizeMatchText(product.halal_status);
  if (productStatus === "haram") {
    return {
      status: "Haram",
      confidence: 0.95,
      reasons: toStringArray(product.halal_reasons).length > 0
        ? toStringArray(product.halal_reasons)
        : ["The matched product record is marked Haram."],
      evidenceLevel: product.halal_evidence_level || "Dataset product policy",
      certified: false,
      recommendationEligible: false,
      ingredientFlags: ingredientSummary.ingredientFlags || [],
      classificationMethod: "Dataset product policy plus ingredient/additive rule analysis",
    };
  }

  if (productStatus === "halal" && ingredientSummary.status !== "Haram") {
    const sourceSensitiveFlags = details
      .filter((item) => item.halalSourceSensitive === true)
      .map((item) => ({
        name: item.name,
        status: item.halalStatus,
        reason: item.halalReason || "",
        triggers: item.halalTriggers || [],
      }));
    return {
      status: ingredientSummary.status === "Doubtful" ? "Doubtful" : "Halal",
      confidence: ingredientSummary.status === "Doubtful"
        ? ingredientSummary.confidence
        : Math.max(0.88, Number(ingredientSummary.confidence) || 0),
      reasons: [
        ...toStringArray(product.halal_reasons),
        ingredientSummary.status === "Doubtful"
          ? "The product is from a halal Pakistani-market dataset, but one or more source-sensitive ingredients still need label/source verification."
          : "Matched Pakistani-market product is treated as halal and no haram marker was detected.",
      ].filter(Boolean),
      evidenceLevel: product.halal_evidence_level || "Dataset product policy with ingredient review",
      certified: false,
      recommendationEligible: product.halal_recommendation_eligible === true,
      ingredientFlags: sourceSensitiveFlags.length > 0
        ? sourceSensitiveFlags
        : ingredientSummary.ingredientFlags || [],
      classificationMethod: "Dataset product policy plus ingredient/additive rule analysis",
    };
  }

  if (
    productStatus === "doubtful" ||
    productStatus === "unknown" ||
    productStatus.includes("certification")
  ) {
    return ingredientSummary.status === "Halal"
      ? {
          ...ingredientSummary,
          status: "Doubtful",
          confidence: Math.min(0.72, Number(ingredientSummary.confidence) || 0.72),
          reasons: [
            "The matched product record does not provide enough halal evidence.",
            ...ingredientSummary.reasons,
          ],
          evidenceLevel: product.halal_evidence_level || "Ingredient review only",
          recommendationEligible: false,
        }
      : {
          ...ingredientSummary,
          evidenceLevel: product.halal_evidence_level || "Ingredient review only",
          recommendationEligible: false,
        };
  }

  return {
    ...ingredientSummary,
    reasons: ingredientSummary.reasons,
    evidenceLevel: product.halal_evidence_level || "Ingredient review only",
    certified: false,
    recommendationEligible: product.halal_recommendation_eligible === true,
  };
};







const OCR_ALLOWED_TEXT_FIELDS = [
  "ingredients",
  "productIngredients",
  "ocrText",
  "scannedText",
  "text",
];

const OCR_STOP_WORDS = new Set([
  "ingredients",
  "ingredient",
  "contains",
  "contain",
  "allergy",
  "advice",
  "nutrition",
  "nutritional",
  "information",
  "serving",
  "energy",
  "fat",
  "saturates",
  "carbohydrate",
  "protein",
  "sodium",
  "fibre",
  "fiber",
  "calories",
  "kcal",
  "kj",
  "per",
  "100g",
  "100ml",
  "best",
  "before",
  "expiry",
  "date",
  "storage",
  "store",
  "cool",
  "dry",
  "place",
  "manufactured",
  "manufacturer",
  "packed",
  "product",
  "barcode",
  "net",
  "weight",
  "volume",
  "directions",
  "usage",
  "warning",
  "warnings",
  "made",
  "may",
  "also",
]);

const INGREDIENT_SYNONYMS = {
  sulphites: "sulfites",
  sulphite: "sulfite",
  colour: "color",
  colours: "colors",
  flavour: "flavor",
  flavours: "flavors",
  soya: "soy",
  arachis: "peanut",
  groundnut: "peanut",
  "mono sodium glutamate": "monosodium glutamate",
  msg: "monosodium glutamate",
  e621: "monosodium glutamate",
  "e 621": "monosodium glutamate",
  "high fructose corn syrup": "hfcs",
};

const normalizeIngredientText = (value) => {
  return String(value || "")
    .toLowerCase()
    .replace(/\r/g, "\n")
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/[|•●▪◆]/g, ",")
    .replace(/\+/g, ",")
    .replace(/\s+/g, " ")
    .trim();
};

const valueToText = (value) => {
  if (value === null || value === undefined) return "";

  if (Array.isArray(value)) {
    return value
      .map((item) => {
        if (item === null || item === undefined) return "";
        if (typeof item === "string") return item;
        if (typeof item === "object") {
          return item.name || item.text || item.ingredient || item.value || "";
        }
        return String(item);
      })
      .join(", ");
  }

  if (typeof value === "object") {
    return value.name || value.text || value.ingredient || value.value || "";
  }

  return String(value || "");
};

const extractRawOcrTextFromBody = (body = {}) => {
  const values = [];

  for (const field of OCR_ALLOWED_TEXT_FIELDS) {
    if (body[field]) values.push(body[field]);
  }

  if (body.scanResult && typeof body.scanResult === "object") {
    for (const field of OCR_ALLOWED_TEXT_FIELDS) {
      if (body.scanResult[field]) values.push(body.scanResult[field]);
    }
  }

  return values.map(valueToText).filter(Boolean).join(", ");
};

const isolateIngredientSection = (text) => {
  let clean = normalizeIngredientText(text);

  const startPatterns = [
    /ingredients?\s*[:\-]/i,
    /composition\s*[:\-]/i,
    /contains?\s*[:\-]/i,
  ];

  for (const pattern of startPatterns) {
    const match = clean.match(pattern);
    if (match && match.index >= 0) {
      clean = clean.slice(match.index + match[0].length);
      break;
    }
  }

  const stopPatterns = [
    /\bnutrition(al)?\s+information\b/i,
    /\ballergy\s+advice\b/i,
    /\bstorage\b/i,
    /\bdirections\b/i,
    /\bserving\s+suggestion\b/i,
    /\bmanufacturer\b/i,
    /\bmanufactured\b/i,
    /\bpacked\b/i,
    /\bexpiry\b/i,
    /\bbest\s+before\b/i,
    /\bbarcode\b/i,
    /\bnet\s+weight\b/i,
  ];

  let stopIndex = -1;
  for (const pattern of stopPatterns) {
    const match = clean.match(pattern);
    if (match && match.index >= 0) {
      if (stopIndex === -1 || match.index < stopIndex) stopIndex = match.index;
    }
  }

  if (stopIndex > 0) clean = clean.slice(0, stopIndex);

  return clean.trim();
};

const fixCommonOcrWord = (word) => {
  let fixed = String(word || "").trim();


  if (/[a-zA-Z]/.test(fixed) && /\d/.test(fixed)) {
    fixed = fixed
      .replace(/0/g, "o")
      .replace(/1/g, "l")
      .replace(/5/g, "s")
      .replace(/@/g, "a")
      .replace(/\$/g, "s");
  }

  return fixed;
};

const cleanSingleIngredient = (item) => {
  let ingredient = String(item || "")
    .toLowerCase()
    .replace(/\([^)]*\)/g, " ")
    .replace(/\[[^\]]*\]/g, " ")
    .replace(/\d+(\.\d+)?\s*(g|mg|kg|ml|l|kcal|kj|%)\b/gi, " ")
    .replace(/\be\s*-\s*/gi, "e")
    .replace(/[^a-z0-9\s\-]/gi, " ")
    .replace(/\s+/g, " ")
    .trim();

  ingredient = ingredient
    .split(" ")
    .map(fixCommonOcrWord)
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();

  if (INGREDIENT_SYNONYMS[ingredient]) {
    ingredient = INGREDIENT_SYNONYMS[ingredient];
  }

  return ingredient;
};

const isValidIngredient = (ingredient) => {
  if (!ingredient) return false;
  if (ingredient.length < 2) return false;
  if (ingredient.length > 60) return false;
  if (!/[a-z]/i.test(ingredient)) return false;
  if (/^\d+$/.test(ingredient)) return false;
  if (OCR_STOP_WORDS.has(ingredient)) return false;

  const words = ingredient.split(/\s+/).filter(Boolean);
  if (words.length > 7) return false;

  const stopWordCount = words.filter((w) => OCR_STOP_WORDS.has(w)).length;
  if (words.length > 0 && stopWordCount / words.length > 0.6) return false;

  return true;
};

const splitIngredientsSmart = (text) => {
  let clean = isolateIngredientSection(text);

  clean = clean
    .replace(/\band\/or\b/gi, ",")
    .replace(/\band\b/gi, ",")
    .replace(/\bmay contain\b/gi, ", may contain ")
    .replace(/\bcontains?\b/gi, ",")
    .replace(/[;:\n]/g, ",")
    .replace(/\s*,\s*/g, ",")
    .replace(/,+/g, ",");

  return clean
    .split(",")
    .map(cleanSingleIngredient)
    .filter(isValidIngredient);
};

const removeDuplicateIngredients = (ingredients) => {
  const seen = new Set();
  const finalIngredients = [];

  for (const ingredient of ingredients) {
    const key = String(ingredient || "").toLowerCase().trim();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    finalIngredients.push(ingredient);
  }

  return finalIngredients;
};

const calculateOcrConfidence = (rawText, ingredients) => {
  const text = String(rawText || "").trim();

  if (!text) {
    return {
      confidence: 0,
      quality: "Failed",
      message: "No OCR text received from frontend.",
    };
  }

  if (ingredients.length === 0) {
    return {
      confidence: 20,
      quality: "Poor",
      message: "OCR text was received, but no valid ingredients were extracted.",
    };
  }

  if (ingredients.length <= 2) {
    return {
      confidence: 55,
      quality: "Medium",
      message: "Only a few ingredients were found. Please check the product image quality.",
    };
  }

  if (ingredients.length >= 3 && ingredients.length <= 40) {
    return {
      confidence: 90,
      quality: "Good",
      message: "Ingredients extracted successfully.",
    };
  }

  return {
    confidence: 70,
    quality: "Review Needed",
    message: "Many ingredients were detected. Please review extracted ingredients once.",
  };
};

const cleanOcrIngredients = (rawInput) => {
  const rawText = extractRawOcrTextFromBody(
    typeof rawInput === "object" && !Array.isArray(rawInput)
      ? rawInput
      : { ingredients: rawInput }
  );

  const ingredients = removeDuplicateIngredients(splitIngredientsSmart(rawText));
  const ocrValidation = calculateOcrConfidence(rawText, ingredients);

  return {
    rawText,
    ingredients,
    ingredientCount: ingredients.length,
    ocrValidation,
  };
};



const looksLikeFoodIngredientLabel = (rawText, ingredients = []) => {
  const text = String(rawText || "").toLowerCase();

  if (!text.trim()) return false;

  const strongLabelWords = [
    "ingredients:",
    "ingredient:",
    "ingredients",
    "contains:",
    "contains",
    "may contain",
    "allergy advice",
    "allergen",
    "nutrition",
    "nutritional information",
  ];

  const commonFoodWords = [
    "salt",
    "sugar",
    "wheat",
    "flour",
    "milk",
    "soy",
    "soya",
    "oil",
    "palm",
    "cocoa",
    "butter",
    "cream",
    "starch",
    "glucose",
    "fructose",
    "syrup",
    "preservative",
    "emulsifier",
    "flavour",
    "flavor",
    "colour",
    "color",
    "acid",
    "citric",
    "lecithin",
    "protein",
    "fiber",
    "fibre",
    "yeast",
    "spice",
    "spices",
    "onion",
    "garlic",
    "tomato",
    "cheese",
    "egg",
    "peanut",
    "sesame",
    "oats",
    "barley",
    "rice",
    "corn",
    "maize",
    "maltodextrin",
    "monosodium",
    "sodium",
  ];

  const obviousStoryWords = [
    "chapter",
    "page",
    "novel",
    "story",
    "said",
    "asked",
    "looked",
    "walked",
    "thought",
    "door",
    "room",
    "eyes",
    "hand",
    "hands",
    "rage",
    "finger",
    "fingers",
    "night",
    "morning",
  ];

  const strongMatches = strongLabelWords.filter((w) => text.includes(w)).length;
  const foodMatches = commonFoodWords.filter((w) => text.includes(w)).length;
  const storyMatches = obviousStoryWords.filter((w) => text.includes(w)).length;


  if (text.includes("ingredients:") || text.includes("ingredient:")) return true;


  if (foodMatches >= 3 && ingredients.length >= 3) return true;


  if (strongMatches >= 2 && ingredients.length >= 2) return true;


  if (storyMatches >= 3 && foodMatches < 3) return false;

  return false;
};






const buildScanHistoryData = (body, user) => {
  const extracted = cleanOcrIngredients(body);

  return {
    userId: user._id,
    userName: body.userName || user.fullName || "Primary User",
    userEmail: body.userEmail || user.email || "",
    rawOcrText: extracted.rawText,
    ocrValidation: extracted.ocrValidation,
    ingredients: extracted.ingredients,
    ingredientCount: extracted.ingredientCount,
    scanResult: {
      ...(body.scanResult && typeof body.scanResult === "object" ? body.scanResult : {}),
      rawOcrText: extracted.rawText,
      ocrValidation: extracted.ocrValidation,
      extractedIngredients: extracted.ingredients,
    },
  };
};

const saveScanHistoryHandler = async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "userId is required to save scan history" });
    }

    if (!isValidObjectId(userId)) {
      return res.status(400).json({
        message: "Invalid user ID",
        receivedUserId: userId,
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        message: "User not found. Scan history was not saved.",
        receivedUserId: userId,
      });
    }

    const scanData = buildScanHistoryData(req.body, user);

    if (!scanData.ingredients || scanData.ingredients.length === 0) {
      return res.status(422).json({
        message: "OCR could not detect valid ingredients. Please scan a clearer ingredients label.",
        rawOcrText: scanData.scanResult.rawOcrText,
        ingredients: [],
        ocrValidation: scanData.scanResult.ocrValidation,
      });
    }

    if (!looksLikeFoodIngredientLabel(scanData.scanResult.rawOcrText, scanData.ingredients)) {
      return res.status(422).json({
        message: "This image does not look like a food ingredients label. Please scan only the product ingredients section.",
        rawOcrText: scanData.scanResult.rawOcrText,
        ingredients: [],
        ocrValidation: {
          ...scanData.scanResult.ocrValidation,
          confidence: 0,
          quality: "Invalid Scan",
        },
      });
    }

    const history = await ScanHistory.create(scanData);
    const ocrResult = await OcrResult.create({
      userId,
      scanHistoryId: history._id,
      rawText: scanData.rawOcrText || scanData.scanResult?.rawOcrText || "",
      extractedIngredients: scanData.ingredients || [],
      ingredientCount: scanData.ingredientCount || 0,
      validation: scanData.ocrValidation || scanData.scanResult?.ocrValidation || {},
      scanResult: scanData.scanResult || {},
      source: "mobile_ocr",
    });

    await ScanHistory.findByIdAndUpdate(history._id, {
      $set: {
        ocrResultId: ocrResult._id,
        "scanResult.ocrResultId": ocrResult._id,
      },
    });

    await logActivity({
      userId,
      action: "scan_history_saved",
      entityType: "ScanHistory",
      entityId: history._id,
      metadata: {
        ocrResultId: ocrResult._id,
        ingredientCount: history.ingredientCount,
        ocrQuality: history.ocrValidation?.quality || "",
      },
    });

    res.status(201).json({
      message: "Scan history saved successfully",
      collection: "scanhistories",
      history,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while saving scan history",
      error: error.message,
    });
  }
};

const getScanHistoryHandler = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const user = await User.findById(userId).select("_id fullName email");
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const history = await ScanHistory.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    res.status(200).json({
      message: "Scan history fetched successfully",
      collection: "scanhistories",
      user: {
        _id: user._id,
        fullName: user.fullName,
        email: user.email,
      },
      count: history.length,
      history,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while fetching scan history",
      error: error.message,
    });
  }
};

const deleteScanHistoryHandler = async (req, res) => {
  try {
    const { scanId } = req.params;
    const { userId } = req.query;

    if (!isValidObjectId(scanId)) {
      return res.status(400).json({ message: "Invalid scan history ID" });
    }

    const filter = { _id: scanId };

    if (userId) {
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: "Invalid user ID" });
      }
      filter.userId = userId;
    }

    const deleted = await ScanHistory.findOneAndDelete(filter);

    if (!deleted) {
      return res.status(404).json({ message: "Scan history record not found" });
    }

    res.status(200).json({
      message: "Scan history deleted successfully",
      deletedId: scanId,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while deleting scan history",
      error: error.message,
    });
  }
};

app.post("/scan-history", saveScanHistoryHandler);
app.post("/api/scan-history", saveScanHistoryHandler);

app.get("/scan-history/:userId", getScanHistoryHandler);
app.get("/api/scan-history/:userId", getScanHistoryHandler);

app.delete("/scan-history/item/:scanId", deleteScanHistoryHandler);
app.delete("/api/scan-history/item/:scanId", deleteScanHistoryHandler);





app.get("/", (req, res) => {
  res.send("Server is running!");
});

app.get("/api/test-db", async (req, res) => {
  try {
    const collections = await mongoose.connection.db.listCollections().toArray();
    res.status(200).json({
      message: "MongoDB connected!",
      collections: collections.map((c) => c.name),
    });
  } catch (err) {
    res.status(500).json({
      error: "MongoDB connection failed",
      details: err.message,
    });
  }
});

app.post("/api/test-ocr", async (req, res) => {
  try {
    const extracted = cleanOcrIngredients(req.body);

    if (extracted.ingredients.length === 0) {
      return res.status(422).json({
        message: "OCR validation failed. No valid ingredients found.",
        rawText: extracted.rawText,
        ingredients: [],
        ingredientCount: 0,
        ocrValidation: extracted.ocrValidation,
      });
    }

    if (!looksLikeFoodIngredientLabel(extracted.rawText, extracted.ingredients)) {
      return res.status(422).json({
        message: "This image does not look like a food ingredients label. Please scan only the product ingredients section.",
        rawText: extracted.rawText,
        ingredients: [],
        ingredientCount: 0,
        ocrValidation: {
          ...extracted.ocrValidation,
          confidence: 0,
          quality: "Invalid Scan",
        },
      });
    }

    res.status(200).json({
      message: "OCR ingredients extracted successfully",
      rawText: extracted.rawText,
      ingredients: extracted.ingredients,
      ingredientCount: extracted.ingredientCount,
      ocrValidation: extracted.ocrValidation,
    });
  } catch (error) {
    res.status(500).json({
      message: "OCR test failed",
      error: error.message,
    });
  }
});

app.get("/api/fix-preferences-index", async (req, res) => {
  try {
    await fixPreferenceIndexes();
    const primaryIndexes = await PrimaryPreference.collection.indexes();
    const familyIndexes = await FamilyPreference.collection.indexes();

    res.status(200).json({
      message: "Preference indexes fixed successfully",
      primaryIndexes,
      familyIndexes,
    });
  } catch (error) {
    res.status(500).json({
      message: "Index fix failed",
      error: error.message,
    });
  }
});




app.post("/register", async (req, res) => {
  try {
    const fullName = String(req.body.fullName || "").trim();
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || "");
    const mobileNumber = String(req.body.mobileNumber || "").trim();
    const dateOfBirth = String(req.body.dateOfBirth || "").trim();

    if (!fullName || fullName.length < 2) {
      return res.status(400).json({ message: "Full name is required", error: "Full name is required" });
    }

    if (!isValidEmail(email)) {
      return res.status(400).json({ message: "Valid email is required", error: "Valid email is required" });
    }

    if (!isValidPassword(password)) {
      return res.status(400).json({
        message: "Password must be at least 6 characters and include letters and numbers",
        error: "Password must be at least 6 characters and include letters and numbers",
      });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "Email already registered", error: "Email already registered" });
    }

    const user = await User.create({
      fullName,
      email,
      password,
      mobileNumber,
      dateOfBirth,
    });

    res.status(201).json(await buildUserSession(user, "User registered successfully"));
  } catch (err) {
    res.status(500).json({ message: "Registration failed", error: err.message });
  }
});

app.post("/login", async (req, res) => {
  const email = normalizeEmail(req.body.email);
  const password = String(req.body.password || "");

  try {
    if (!isValidEmail(email) || !password) {
      return res.status(400).json({ message: "Valid email and password are required" });
    }

    const user = await User.findOne({ email });

    if (!user) return res.status(404).json({ message: "User not found" });
    if (!user.password && user.googleId) {
      return res.status(401).json({ message: "This account uses Google Sign-In. Please continue with Google." });
    }
    if (user.password !== password) {
      return res.status(401).json({ message: "Invalid password" });
    }

    res.status(200).json(await buildUserSession(user, "Login successful"));
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

app.post("/api/signup", async (req, res) => {
  try {
    const fullName = String(req.body.fullName || "").trim();
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || "");
    const mobileNumber = String(req.body.mobileNumber || "").trim();
    const dateOfBirth = String(req.body.dateOfBirth || "").trim();

    if (!fullName || fullName.length < 2) {
      return res.status(400).json({ message: "Full name is required", error: "Full name is required" });
    }

    if (!isValidEmail(email)) {
      return res.status(400).json({ message: "Valid email is required", error: "Valid email is required" });
    }

    if (!isValidPassword(password)) {
      return res.status(400).json({
        message: "Password must be at least 6 characters and include letters and numbers",
        error: "Password must be at least 6 characters and include letters and numbers",
      });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "Email already registered", error: "Email already registered" });
    }

    const user = await User.create({
      fullName,
      email,
      password,
      mobileNumber,
      dateOfBirth,
    });

    res.status(201).json(await buildUserSession(user, "User created"));
  } catch (err) {
    res.status(500).json({ message: "Signup failed", error: err.message });
  }
});

app.post("/api/google-login", async (req, res) => {
  const name = String(req.body.name || req.body.fullName || "Google User").trim();
  const email = normalizeEmail(req.body.email);
  const googleId = String(req.body.googleId || "").trim();

  try {
    if (!isValidEmail(email)) {
      return res.status(400).json({ message: "Valid Google email is required" });
    }

    let user = await User.findOne({ email });

    if (!user) {
      user = await User.create({
        fullName: name,
        email,
        googleId,
      });
    } else {
      const updates = {};
      if (!user.googleId && googleId) updates.googleId = googleId;
      if ((!user.fullName || user.fullName === "Google User") && name) updates.fullName = name;
      if (Object.keys(updates).length) {
        user = await User.findByIdAndUpdate(user._id, { $set: updates }, { new: true });
      }
    }

    res.status(200).json(await buildUserSession(user, "Google login successful"));
  } catch (err) {
    res.status(500).json({ message: "Google login failed", error: err.message });
  }
});

app.post("/api/forgot-password", async (req, res) => {
  const email = normalizeEmail(req.body.email);

  try {
    if (!isValidEmail(email)) {
      return res.status(400).json({ message: "Valid email is required" });
    }

    const genericMessage = "If an account exists for this email, a password reset code has been sent.";
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(200).json({ message: genericMessage });
    }

    if (!user.password && user.googleId) {
      return res.status(400).json({ message: "This account uses Google Sign-In and does not have a password to reset." });
    }

    const resetToken = crypto.randomBytes(24).toString("hex");
    user.passwordResetTokenHash = hashResetToken(resetToken);
    user.passwordResetExpiresAt = new Date(Date.now() + 15 * 60 * 1000);
    user.passwordResetUsedAt = null;
    await user.save();

    let delivery = { attempted: false, status: "not_configured" };
    try {
      delivery = await sendPasswordResetEmail({ email, token: resetToken, user });
    } catch (error) {
      delivery = { attempted: true, status: "failed", message: error.message };
    }

    await logActivity({
      userId: user._id,
      action: "password_reset_requested",
      entityType: "User",
      entityId: user._id,
      metadata: { email, deliveryStatus: delivery.status },
    });

    res.status(200).json({
      message: genericMessage,
      delivery,
      ...(process.env.NODE_ENV === "production" ? {} : { devResetToken: resetToken }),
    });
  } catch (err) {
    res.status(500).json({ message: "Unable to process password reset request", error: err.message });
  }
});

app.post("/api/reset-password", async (req, res) => {
  const email = normalizeEmail(req.body.email);
  const token = String(req.body.token || "").trim();
  const password = String(req.body.password || "");

  try {
    if (!isValidEmail(email) || !token) {
      return res.status(400).json({ message: "Email and reset code are required" });
    }

    if (!isValidPassword(password)) {
      return res.status(400).json({
        message: "Password must be at least 6 characters and include letters and numbers",
      });
    }

    const user = await User.findOne({
      email,
      passwordResetTokenHash: hashResetToken(token),
      passwordResetExpiresAt: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).json({ message: "Invalid or expired reset code" });
    }

    user.password = password;
    user.passwordResetUsedAt = new Date();
    user.passwordResetTokenHash = "";
    user.passwordResetExpiresAt = null;
    await user.save();

    await logActivity({
      userId: user._id,
      action: "password_reset_completed",
      entityType: "User",
      entityId: user._id,
      metadata: { email },
    });

    res.status(200).json({ message: "Password reset successfully" });
  } catch (err) {
    res.status(500).json({ message: "Unable to reset password", error: err.message });
  }
});




app.post("/family-members", auth, async (req, res) => {
  try {
    const {
      userId,
      name,
      age,
      gender,
      relation,
      weight,
      healthConditions,
      invitationEmail,
      email,
    } = req.body;

    if (!userId || !name) {
      return res.status(400).json({ message: "userId and name are required" });
    }

    if (!isValidObjectId(userId)) {
      return res.status(400).json({
        message: "Invalid user ID",
        receivedUserId: userId,
      });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        message: "User not found",
        receivedUserId: userId,
      });
    }

    const finalGender = ["Male", "Female", "Other"].includes(gender)
      ? gender
      : "Other";
    const finalInvitationEmail = normalizeEmail(invitationEmail || email);
    const invitationToken = finalInvitationEmail ? createInvitationToken() : "";
    const invitedUser = finalInvitationEmail
      ? await User.findOne({ email: finalInvitationEmail }).select("_id").lean()
      : null;

    const newMember = await FamilyMember.create({
      userId,
      name: String(name).trim(),
      age: numberOrDefault(age, 1),
      gender: finalGender,
      relation: relation || "Family",
      weight: weight || "",
      healthConditions: toStringArray(healthConditions),
      isPrimary: false,
      invitationEmail: finalInvitationEmail,
      invitationStatus: finalInvitationEmail ? "pending" : "local_profile",
      connectionStatus: finalInvitationEmail ? "pending" : "local_profile",
      invitationToken,
      invitedUserId: invitedUser?._id || null,
      invitedAt: finalInvitationEmail ? new Date() : null,
    });

    await User.findByIdAndUpdate(userId, {
      $addToSet: { familyMembers: newMember._id },
    });

    const notification = finalInvitationEmail
      ? await createFamilyInviteNotification({ primaryUser: user, member: newMember })
      : null;

    await logActivity({
      userId,
      action: finalInvitationEmail ? "family_invitation_created" : "family_member_created",
      entityType: "FamilyMember",
      entityId: newMember._id,
      metadata: {
        memberName: newMember.name,
        invitationEmail: finalInvitationEmail,
        invitationStatus: newMember.invitationStatus,
      },
    });

    res.status(201).json({
      message: finalInvitationEmail
        ? "Family member saved and invitation notification created successfully"
        : "Family member saved successfully",
      member: newMember,
      notification,
      _id: newMember._id,
      name: newMember.name,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while saving family member",
      error: error.message,
    });
  }
});

app.get("/family-members/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const familyMembers = await FamilyMember.find({ userId }).sort({
      isPrimary: -1,
      createdAt: 1,
    });

    res.status(200).json(familyMembers);
  } catch (error) {
    res.status(500).json({
      message: "Server error while fetching family members",
      error: error.message,
    });
  }
});

app.get("/family-members/member/:memberId", auth, async (req, res) => {
  try {
    const { memberId } = req.params;

    if (!isValidObjectId(memberId)) {
      return res.status(400).json({ message: "Invalid member ID" });
    }

    const member = await FamilyMember.findById(memberId);

    if (!member) {
      return res.status(404).json({ message: "Family member not found" });
    }

    res.status(200).json(member);
  } catch (error) {
    res.status(500).json({
      message: "Server error while fetching family member",
      error: error.message,
    });
  }
});

app.put("/family-members/:memberId", auth, async (req, res) => {
  try {
    const { memberId } = req.params;
    const updates = { ...req.body };

    if (!isValidObjectId(memberId)) {
      return res.status(400).json({ message: "Invalid member ID" });
    }

    delete updates.userId;
    delete updates.isPrimary;

    if (updates.gender && !["Male", "Female", "Other"].includes(updates.gender)) {
      updates.gender = "Other";
    }

    if (updates.age) {
      updates.age = numberOrDefault(updates.age, 1);
    }

    if (Array.isArray(updates.healthConditions)) {
      updates.healthConditions = toStringArray(updates.healthConditions);
    }
    if (updates.invitationEmail || updates.email) {
      updates.invitationEmail = normalizeEmail(updates.invitationEmail || updates.email);
      delete updates.email;
    }

    const updatedMember = await FamilyMember.findByIdAndUpdate(
      memberId,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!updatedMember) {
      return res.status(404).json({ message: "Family member not found" });
    }

    if (updates.name) {
      await FamilyPreference.updateMany(
        { memberId },
        { $set: { memberName: String(updates.name).trim() } }
      );
    }

    res.status(200).json({
      message: "Family member updated successfully",
      member: updatedMember,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while updating family member",
      error: error.message,
    });
  }
});

app.put("/api/family-members/:memberId/permissions", auth, async (req, res) => {
  try {
    const { memberId } = req.params;
    const { userId, permissions } = req.body;

    if (!isValidObjectId(memberId)) return res.status(400).json({ message: "Invalid member ID" });
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Valid userId is required" });

    const allowed = [
      "canViewScans",
      "canShareRecommendations",
      "canManageOwnPreferences",
      "primaryCanManagePreferences",
    ];
    const nextPermissions = {};
    for (const key of allowed) {
      if (typeof permissions?.[key] === "boolean") {
        nextPermissions[`permissions.${key}`] = permissions[key];
      }
    }

    const member = await FamilyMember.findOneAndUpdate(
      { _id: memberId, userId },
      { $set: nextPermissions },
      { new: true }
    );

    if (!member) return res.status(404).json({ message: "Family member not found for this user" });

    await logActivity({
      userId,
      action: "family_permissions_updated",
      entityType: "FamilyMember",
      entityId: member._id,
      metadata: { permissions: member.permissions },
    });

    res.status(200).json({ message: "Family permissions updated", member });
  } catch (error) {
    res.status(500).json({ message: "Server error while updating family permissions", error: error.message });
  }
});

app.get("/api/family-members/:userId/connected", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Invalid user ID" });

    const members = await FamilyMember.find({ userId })
      .select("-invitationToken")
      .sort({ connectionStatus: 1, createdAt: 1 })
      .lean();

    res.status(200).json({
      message: "Connected family members fetched successfully",
      count: members.length,
      activeCount: members.filter((member) => Boolean(member.lastActiveAt)).length,
      members,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while fetching connected members", error: error.message });
  }
});

app.delete("/family-members/:memberId", auth, async (req, res) => {
  try {
    const { memberId } = req.params;

    if (!isValidObjectId(memberId)) {
      return res.status(400).json({ message: "Invalid member ID" });
    }

    const member = await FamilyMember.findById(memberId);

    if (!member) {
      return res.status(404).json({ message: "Family member not found" });
    }

    await FamilyMember.findByIdAndDelete(memberId);

    await User.findByIdAndUpdate(member.userId, {
      $pull: { familyMembers: member._id },
    });



    await FamilyPreference.deleteMany({ userId: member.userId, memberId: member._id });
    await FamilyNotification.deleteMany({ memberId: member._id });

    res.status(200).json({
      message: "Family member and their preferences deleted successfully",
      deletedMemberId: memberId,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while deleting family member",
      error: error.message,
    });
  }
});

app.get("/family-members/count/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const count = await FamilyMember.countDocuments({ userId });
    res.status(200).json({ count });
  } catch (error) {
    res.status(500).json({
      message: "Server error while counting family members",
      error: error.message,
    });
  }
});


const hasPreferencePayload = (payload) => {
  const fields = [
    "allergens", "customAllergens", "additives", "customAdditives",
    "diets", "customDiets", "ingredients", "customIngredients",
    "nutritions", "customNutritions", "healthConditions",
    "customHealthConditions", "avoidedIngredients",
    "customAvoidedIngredients", "preferredIngredients",
    "customPreferredIngredients", "productCategories",
    "customProductCategories", "recommendationSettings",
    "customRecommendationSettings",
  ];
  return fields.some((field) => toStringArray(payload?.[field]).length > 0);
};

const saveFamilyPreferenceFromMember = async ({ member, memberUser, payload }) => {
  const primaryUser = await User.findById(member.userId).select("_id fullName email").lean();
  if (!primaryUser) throw new Error("Primary user for this family member was not found");

  return FamilyPreference.findOneAndUpdate(
    { userId: member.userId, memberId: member._id },
    {
      $set: {
        userId: member.userId,
        userName: primaryUser.fullName || primaryUser.email || "Primary User",
        memberId: member._id,
        memberName: member.name,
        memberUserId: memberUser._id,
        preferenceOwnerType: "family",
        preferenceSource: "family_member",
        updatedByUserId: memberUser._id,
        ...buildPreferenceData(payload),
      },
    },
    { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
  );
};

const getNotificationForRecipient = async (notificationId, user) => {
  if (!isValidObjectId(notificationId)) return null;
  const email = normalizeEmail(user.email);
  return FamilyNotification.findOne({
    _id: notificationId,
    $or: [
      { recipientUserId: user._id },
      { recipientEmail: email },
    ],
  });
};

app.get("/api/notifications/user/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Invalid user ID" });

    const user = await User.findById(userId).select("_id email fullName").lean();
    if (!user) return res.status(404).json({ message: "User not found" });

    const email = normalizeEmail(user.email);
    const notifications = await FamilyNotification.find({
      $or: [
        { recipientUserId: user._id },
        { recipientEmail: email },
      ],
    }).sort({ createdAt: -1 }).lean();

    res.status(200).json({
      collection: "familynotifications",
      count: notifications.length,
      notifications,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while fetching notifications", error: error.message });
  }
});

app.post("/api/notifications/:notificationId/read", auth, async (req, res) => {
  try {
    const { notificationId } = req.params;
    const { userId } = req.body;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Valid userId is required" });

    const user = await User.findById(userId).select("_id email").lean();
    if (!user) return res.status(404).json({ message: "User not found" });

    const notification = await getNotificationForRecipient(notificationId, user);
    if (!notification) return res.status(404).json({ message: "Notification not found for this user" });

    notification.status = "read";
    notification.readAt = notification.readAt || new Date();
    await notification.save();

    res.status(200).json({ message: "Notification marked as read", notification });
  } catch (error) {
    res.status(500).json({ message: "Server error while updating notification", error: error.message });
  }
});

app.post("/api/family-invitations/:notificationId/accept", auth, async (req, res) => {
  try {
    const { notificationId } = req.params;
    const { userId } = req.body;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Valid userId is required" });

    const memberUser = await User.findById(userId).select("_id email fullName").lean();
    if (!memberUser) return res.status(404).json({ message: "User not found" });

    const notification = await getNotificationForRecipient(notificationId, memberUser);
    if (!notification || notification.type !== "family_invite") {
      return res.status(404).json({ message: "Family invitation not found for this user" });
    }
    if (notification.actionStatus !== "pending") {
      return res.status(409).json({ message: `Invitation already ${notification.actionStatus}` });
    }

    const member = await FamilyMember.findById(notification.memberId);
    if (!member) return res.status(404).json({ message: "Family member profile not found" });

    const acceptedAt = new Date();
    member.invitationStatus = "accepted";
    member.connectionStatus = "connected";
    member.invitedUserId = memberUser._id;
    member.acceptedAt = acceptedAt;
    member.lastActiveAt = acceptedAt;
    await member.save();

    notification.actionStatus = "accepted";
    notification.status = "read";
    notification.readAt = notification.readAt || acceptedAt;
    notification.actedAt = acceptedAt;
    notification.recipientUserId = memberUser._id;
    await notification.save();

    await FamilyNotification.create({
      type: "family_invite_accepted",
      senderUserId: memberUser._id,
      senderName: memberUser.fullName || memberUser.email || member.name,
      recipientUserId: member.userId,
      memberId: member._id,
      title: "Family request accepted",
      body: `${memberUser.fullName || member.name} accepted the family personalization request.`,
      status: "unread",
      actionStatus: "none",
      payload: {
        memberId: member._id,
        memberName: member.name,
        acceptedUserId: memberUser._id,
      },
      delivery: { inApp: true },
    });

    const preferencePayload = req.body.preferences && typeof req.body.preferences === "object"
      ? req.body.preferences
      : req.body;
    const preferences = hasPreferencePayload(preferencePayload)
      ? await saveFamilyPreferenceFromMember({ member, memberUser, payload: preferencePayload })
      : null;

    if (preferences) {
      await savePreferenceHistory({
        preferences,
        userId: member.userId,
        memberId: member._id,
        ownerType: "family",
        changedByUserId: memberUser._id,
        changeType: "self_updated",
      });
    }

    await logActivity({
      userId: member.userId,
      action: "family_invitation_accepted",
      entityType: "FamilyMember",
      entityId: member._id,
      metadata: {
        acceptedByUserId: memberUser._id,
        acceptedByEmail: memberUser.email,
        preferencesSaved: Boolean(preferences),
      },
    });

    res.status(200).json({
      message: "Family invitation accepted successfully",
      member,
      notification,
      preferences,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while accepting invitation", error: error.message });
  }
});

app.post("/api/family-invitations/:notificationId/decline", auth, async (req, res) => {
  try {
    const { notificationId } = req.params;
    const { userId } = req.body;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Valid userId is required" });

    const memberUser = await User.findById(userId).select("_id email fullName").lean();
    if (!memberUser) return res.status(404).json({ message: "User not found" });

    const notification = await getNotificationForRecipient(notificationId, memberUser);
    if (!notification || notification.type !== "family_invite") {
      return res.status(404).json({ message: "Family invitation not found for this user" });
    }
    if (notification.actionStatus !== "pending") {
      return res.status(409).json({ message: `Invitation already ${notification.actionStatus}` });
    }

    const declinedAt = new Date();
    const member = await FamilyMember.findByIdAndUpdate(
      notification.memberId,
      { $set: { invitationStatus: "declined", connectionStatus: "declined", declinedAt, invitedUserId: memberUser._id } },
      { new: true }
    );

    notification.actionStatus = "declined";
    notification.status = "read";
    notification.readAt = notification.readAt || declinedAt;
    notification.actedAt = declinedAt;
    notification.recipientUserId = memberUser._id;
    await notification.save();

    if (member) {
      await FamilyNotification.create({
        type: "family_invite_declined",
        senderUserId: memberUser._id,
        senderName: memberUser.fullName || memberUser.email || member.name,
        recipientUserId: member.userId,
        memberId: member._id,
        title: "Family request declined",
        body: `${memberUser.fullName || member.name} declined the family personalization request.`,
        status: "unread",
        actionStatus: "none",
        payload: { memberId: member._id, memberName: member.name },
        delivery: { inApp: true },
      });
    }

    if (member) {
      await logActivity({
        userId: member.userId,
        action: "family_invitation_declined",
        entityType: "FamilyMember",
        entityId: member._id,
        metadata: {
          declinedByUserId: memberUser._id,
          declinedByEmail: memberUser.email,
        },
      });
    }

    res.status(200).json({ message: "Family invitation declined", member, notification });
  } catch (error) {
    res.status(500).json({ message: "Server error while declining invitation", error: error.message });
  }
});

app.put("/api/family-members/:memberId/self-preferences", auth, async (req, res) => {
  try {
    const { memberId } = req.params;
    const { userId } = req.body;
    if (!isValidObjectId(memberId)) return res.status(400).json({ message: "Invalid member ID" });
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Valid userId is required" });

    const memberUser = await User.findById(userId).select("_id email fullName").lean();
    if (!memberUser) return res.status(404).json({ message: "User not found" });

    const member = await FamilyMember.findOne({
      _id: memberId,
      invitedUserId: memberUser._id,
      invitationStatus: "accepted",
    });
    if (!member) {
      return res.status(403).json({ message: "This user has not accepted this family profile invitation" });
    }
    if (member.permissions?.canManageOwnPreferences === false) {
      return res.status(403).json({ message: "Preference editing is disabled for this family profile" });
    }

    const preferencePayload = req.body.preferences && typeof req.body.preferences === "object"
      ? req.body.preferences
      : req.body;
    const preferences = await saveFamilyPreferenceFromMember({ member, memberUser, payload: preferencePayload });

    await FamilyMember.findByIdAndUpdate(member._id, { $set: { lastActiveAt: new Date() } });
    await savePreferenceHistory({
      preferences,
      userId: member.userId,
      memberId: member._id,
      ownerType: "family",
      changedByUserId: memberUser._id,
      changeType: "self_updated",
    });

    await logActivity({
      userId: member.userId,
      action: "family_member_preferences_updated",
      entityType: "FamilyPreference",
      entityId: preferences._id,
      metadata: {
        memberId: member._id,
        updatedByUserId: memberUser._id,
        source: "family_member",
      },
    });

    res.status(200).json({
      message: "Family member preferences saved by invited member",
      collection: "familypreferences",
      preferences,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while saving invited member preferences", error: error.message });
  }
});


app.get("/user/:userId/profile", auth, async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const user = await User.findById(userId).select("-password");

    if (!user) return res.status(404).json({ message: "User not found" });

    const familyMembers = await FamilyMember.find({ userId });

    res.status(200).json({
      user,
      familyMembers,
      totalMembers: familyMembers.length,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while fetching profile",
      error: error.message,
    });
  }
});

app.get("/api/users/:userId/settings", auth, async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const user = await User.findById(userId).select("-password -passwordResetTokenHash -passwordResetExpiresAt -passwordResetUsedAt");

    if (!user) return res.status(404).json({ message: "User not found" });

    res.status(200).json({
      message: "Settings loaded successfully",
      user: sanitizeUser(user),
      settings: validSettingsPayload(user.settings || {}),
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while fetching settings",
      error: error.message,
    });
  }
});

app.put("/api/users/:userId/settings", auth, async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const fullName = String(req.body.fullName || "").trim();
    const mobileNumber = String(req.body.mobileNumber || "").trim();
    const dateOfBirth = String(req.body.dateOfBirth || "").trim();

    if (!fullName || fullName.length < 2) {
      return res.status(400).json({ message: "Full name must be at least 2 characters" });
    }

    if (mobileNumber && !/^\+?[0-9]{10,15}$/.test(mobileNumber.replace(/[\s-]/g, ""))) {
      return res.status(400).json({ message: "Enter a valid mobile number" });
    }

    const settings = validSettingsPayload(req.body.settings || {});

    const user = await User.findByIdAndUpdate(
      userId,
      {
        $set: {
          fullName,
          mobileNumber,
          dateOfBirth,
          settings,
        },
      },
      { new: true, runValidators: true }
    ).select("-password -passwordResetTokenHash -passwordResetExpiresAt -passwordResetUsedAt");

    if (!user) return res.status(404).json({ message: "User not found" });

    await PrimaryPreference.updateOne(
      { userId },
      { $set: { userName: fullName } }
    );

    await logActivity({
      userId,
      action: "settings_updated",
      entityType: "User",
      entityId: userId,
      metadata: { settings },
    });

    res.status(200).json({
      message: "Settings saved successfully",
      user: sanitizeUser(user),
      settings,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while saving settings",
      error: error.message,
    });
  }
});





const buildPreferenceData = (body) => ({
  allergens: toStringArray(body.allergens),
  customAllergens: toStringArray(body.customAllergens),
  allergenImportance: body.allergenImportance || "Essential",

  additives: toStringArray(body.additives),
  customAdditives: toStringArray(body.customAdditives),
  additiveImportance: body.additiveImportance || "Essential",

  diets: toStringArray(body.diets),
  customDiets: toStringArray(body.customDiets),
  dietImportance: body.dietImportance || "Essential",

  ingredients: toStringArray(body.ingredients),
  customIngredients: toStringArray(body.customIngredients),
  ingredientImportance: body.ingredientImportance || "Essential",

  nutritions: toStringArray(body.nutritions),
  customNutritions: toStringArray(body.customNutritions),
  nutritionImportance: body.nutritionImportance || "Preferred",

  healthConditions: toStringArray(body.healthConditions),
  customHealthConditions: toStringArray(body.customHealthConditions),
  healthConditionImportance: body.healthConditionImportance || "Essential",

  avoidedIngredients: toStringArray(body.avoidedIngredients),
  customAvoidedIngredients: toStringArray(body.customAvoidedIngredients),
  avoidedIngredientImportance: body.avoidedIngredientImportance || "Essential",

  preferredIngredients: toStringArray(body.preferredIngredients),
  customPreferredIngredients: toStringArray(body.customPreferredIngredients),
  preferredIngredientImportance: body.preferredIngredientImportance || "Preferred",

  productCategories: toStringArray(body.productCategories),
  customProductCategories: toStringArray(body.customProductCategories),
  productCategoryImportance: body.productCategoryImportance || "Preferred",

  recommendationSettings: toStringArray(body.recommendationSettings),
  customRecommendationSettings: toStringArray(body.customRecommendationSettings),
  recommendationSettingImportance: body.recommendationSettingImportance || "Preferred",
});

const buildPreferenceAiFeedback = (preferences) => {
  const summary = summarizePreferences(preferences);
  const avoid = [
    ...combinePreferenceItems(preferences.allergens, preferences.customAllergens),
    ...combinePreferenceItems(preferences.additives, preferences.customAdditives),
    ...combinePreferenceItems(preferences.ingredients, preferences.customIngredients),
    ...combinePreferenceItems(preferences.avoidedIngredients, preferences.customAvoidedIngredients),
  ];
  const goals = [
    ...combinePreferenceItems(preferences.diets, preferences.customDiets),
    ...combinePreferenceItems(preferences.nutritions, preferences.customNutritions),
    ...combinePreferenceItems(preferences.preferredIngredients, preferences.customPreferredIngredients),
  ];
  const categories = combinePreferenceItems(preferences.productCategories, preferences.customProductCategories);

  return {
    summary,
    recommendedProducts: categories.length > 0
      ? categories.map((category) => `Products in ${category} that satisfy your allergy, halal, ingredient, and nutrition settings.`)
      : ["Products with matching nutrition values, safe ingredients, and no selected allergy conflicts."],
    productsToAvoid: avoid.length > 0
      ? avoid.map((item) => `Avoid products containing ${item}.`)
      : ["No specific avoid-list saved yet."],
    ingredientsToAvoid: avoid,
    ingredientsThatMatchGoals: goals,
    explanation:
      "Future scans will compare OCR ingredients, product category, halal status, nutrition values, allergens, and your saved importance levels before ranking recommendations.",
  };
};

const savePreferenceHistory = async ({
  preferences,
  userId,
  memberId = null,
  ownerType = "primary",
  changedByUserId = null,
  changeType = "updated",
}) => {
  if (!preferences?._id) return null;
  const latest = await PreferenceHistory.findOne({
    userId,
    memberId: memberId || null,
    ownerType,
  }).sort({ version: -1 }).lean();
  const version = (latest?.version || 0) + 1;
  return PreferenceHistory.create({
    userId,
    memberId: memberId || null,
    preferenceId: preferences._id,
    ownerType,
    version,
    changeType,
    changedByUserId: isValidObjectId(changedByUserId) ? changedByUserId : userId,
    preferencesSnapshot: preferences.toObject ? preferences.toObject() : preferences,
    aiFeedback: buildPreferenceAiFeedback(preferences),
  });
};

app.post("/api/preferences/save", auth, async (req, res) => {
  try {
    const { userId, userName, memberId, memberName } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "userId is required" });
    }

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID", receivedUserId: userId });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found", receivedUserId: userId });
    }

    const primaryUserName = user.fullName || user.email || "Primary User";
    const finalUserName = userName || primaryUserName;
    const preferenceData = buildPreferenceData(req.body);


    if (!memberId) {
      const preferences = await PrimaryPreference.findOneAndUpdate(
        { userId },
        {
          $set: {
            userId,
            userName: finalUserName,
            preferenceOwnerType: "primary",
            ...preferenceData,
          },
        },
        { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
      );

      await logActivity({
        userId,
        action: "primary_preferences_saved",
        entityType: "PrimaryPreference",
        entityId: preferences._id,
        metadata: { source: "primary_user" },
      });
      const history = await savePreferenceHistory({
        preferences,
        userId,
        ownerType: "primary",
        changedByUserId: user._id,
        changeType: "created",
      });
      await createAppNotification({
        type: "preference_update",
        senderUserId: user._id,
        senderName: primaryUserName,
        recipientUserId: user._id,
        title: "Preferences updated",
        body: "Your recommendation profile was updated and future scans will use the new settings.",
        payload: { preferenceId: preferences._id, version: history?.version || 1 },
      });

      return res.status(200).json({
        message: "Primary user preferences saved separately",
        collection: "primarypreferences",
        preferences,
        aiFeedback: buildPreferenceAiFeedback(preferences),
        preferenceVersion: history?.version || 1,
      });
    }

    if (!isValidObjectId(memberId)) {
      return res.status(400).json({ message: "Invalid member ID", receivedMemberId: memberId });
    }

    const member = await FamilyMember.findOne({ _id: memberId, userId });
    if (!member) {
      return res.status(404).json({
        message: "Family member not found for this primary user",
        receivedUserId: userId,
        receivedMemberId: memberId,
      });
    }

    const finalMemberName = memberName || member.name || "Family Member";

    const preferences = await FamilyPreference.findOneAndUpdate(
      { userId, memberId },
      {
        $set: {
          userId,


          userName: primaryUserName,
          memberId,
          memberName: finalMemberName,
          preferenceOwnerType: "family",
          memberUserId: member.invitedUserId || null,
          preferenceSource: "primary_user",
          updatedByUserId: user._id,
          ...preferenceData,
        },
      },
      { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
    );

    await logActivity({
      userId,
      action: "family_preferences_saved",
      entityType: "FamilyPreference",
      entityId: preferences._id,
      metadata: {
        memberId,
        memberName: finalMemberName,
        source: "primary_user",
      },
    });
    const history = await savePreferenceHistory({
      preferences,
      userId,
      memberId,
      ownerType: "family",
      changedByUserId: user._id,
      changeType: "created",
    });
    await createAppNotification({
      type: "preference_update",
      senderUserId: user._id,
      senderName: primaryUserName,
      recipientUserId: member.invitedUserId || null,
      recipientEmail: member.invitationEmail || "",
      memberId: member._id,
      title: "Family preferences updated",
      body: `${primaryUserName} updated preferences for ${finalMemberName}.`,
      payload: { preferenceId: preferences._id, version: history?.version || 1, memberId },
    });

    res.status(200).json({
      message: "Family member preferences saved separately with primary user name",
      collection: "familypreferences",
      preferences,
      aiFeedback: buildPreferenceAiFeedback(preferences),
      preferenceVersion: history?.version || 1,
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        message: "Duplicate preferences index error. Open /api/fix-preferences-index once and try again.",
        error: error.message,
      });
    }

    res.status(500).json({ message: "Server error while saving preferences", error: error.message });
  }
});

app.get("/api/preferences/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const { memberId, type } = req.query;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    if (memberId) {
      if (!isValidObjectId(memberId)) {
        return res.status(400).json({ message: "Invalid member ID" });
      }

      const preferences = await FamilyPreference.findOne({ userId, memberId });
      return res.status(200).json({
        collection: "familypreferences",
        preferences: preferences || null,
      });
    }

    if (type === "all") {
      const primaryPreferences = await PrimaryPreference.findOne({ userId });
      const familyPreferences = await FamilyPreference.find({ userId }).sort({ updatedAt: -1 });
      return res.status(200).json({
        primaryPreferences: primaryPreferences || null,
        familyPreferences,
      });
    }

    const preferences = await PrimaryPreference.findOne({ userId });
    res.status(200).json({
      collection: "primarypreferences",
      preferences: preferences || null,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while getting preferences", error: error.message });
  }
});

app.put("/api/preferences/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const memberId = req.query.memberId || req.body.memberId;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    const primaryUserName = user.fullName || user.email || "Primary User";
    const finalUserName = req.body.userName || primaryUserName;
    const preferenceData = buildPreferenceData(req.body);

    if (!memberId) {
      const preferences = await PrimaryPreference.findOneAndUpdate(
        { userId },
        { $set: { userId, userName: finalUserName, preferenceOwnerType: "primary", ...preferenceData } },
        { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
      );

      await logActivity({
        userId,
        action: "primary_preferences_updated",
        entityType: "PrimaryPreference",
        entityId: preferences._id,
        metadata: { source: "primary_user" },
      });
      const history = await savePreferenceHistory({
        preferences,
        userId,
        ownerType: "primary",
        changedByUserId: user._id,
        changeType: "updated",
      });
      await createAppNotification({
        type: "preference_update",
        senderUserId: user._id,
        senderName: primaryUserName,
        recipientUserId: user._id,
        title: "Preferences updated",
        body: "Your saved preferences were updated successfully.",
        payload: { preferenceId: preferences._id, version: history?.version || 1 },
      });

      return res.status(200).json({
        message: "Primary user preferences updated separately",
        collection: "primarypreferences",
        preferences,
        aiFeedback: buildPreferenceAiFeedback(preferences),
        preferenceVersion: history?.version || 1,
      });
    }

    if (!isValidObjectId(memberId)) {
      return res.status(400).json({ message: "Valid memberId is required" });
    }

    const member = await FamilyMember.findOne({ _id: memberId, userId });
    if (!member) {
      return res.status(404).json({ message: "Family member not found for this primary user" });
    }

    const preferences = await FamilyPreference.findOneAndUpdate(
      { userId, memberId },
      {
        $set: {
          userId,

          userName: primaryUserName,
          memberId,
          memberName: req.body.memberName || member.name,
          preferenceOwnerType: "family",
          memberUserId: member.invitedUserId || null,
          preferenceSource: "primary_user",
          updatedByUserId: user._id,
          ...preferenceData,
        },
      },
      { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
    );

    await logActivity({
      userId,
      action: "family_preferences_updated",
      entityType: "FamilyPreference",
      entityId: preferences._id,
      metadata: {
        memberId,
        memberName: preferences.memberName,
        source: "primary_user",
      },
    });
    const history = await savePreferenceHistory({
      preferences,
      userId,
      memberId,
      ownerType: "family",
      changedByUserId: user._id,
      changeType: "updated",
    });
    await createAppNotification({
      type: "preference_update",
      senderUserId: user._id,
      senderName: primaryUserName,
      recipientUserId: member.invitedUserId || null,
      recipientEmail: member.invitationEmail || "",
      memberId: member._id,
      title: "Family preferences updated",
      body: `${primaryUserName} updated preferences for ${preferences.memberName || member.name}.`,
      payload: { preferenceId: preferences._id, version: history?.version || 1, memberId },
    });

    res.status(200).json({
      message: "Family member preferences updated separately",
      collection: "familypreferences",
      preferences,
      aiFeedback: buildPreferenceAiFeedback(preferences),
      preferenceVersion: history?.version || 1,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while updating preferences", error: error.message });
  }
});

app.delete("/api/preferences/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const { memberId, type } = req.query;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    if (memberId) {
      if (!isValidObjectId(memberId)) {
        return res.status(400).json({ message: "Invalid member ID" });
      }

      const deleted = await FamilyPreference.findOneAndDelete({ userId, memberId });
      if (deleted) {
        await savePreferenceHistory({
          preferences: deleted,
          userId,
          memberId,
          ownerType: "family",
          changedByUserId: userId,
          changeType: "deleted",
        });
      }
      return res.status(200).json({ message: "This family member preferences deleted successfully" });
    }

    if (type === "all") {
      const primaryDeleted = await PrimaryPreference.findOneAndDelete({ userId });
      if (primaryDeleted) {
        await savePreferenceHistory({
          preferences: primaryDeleted,
          userId,
          ownerType: "primary",
          changedByUserId: userId,
          changeType: "deleted",
        });
      }
      const familyDeleted = await FamilyPreference.find({ userId });
      await FamilyPreference.deleteMany({ userId });
      for (const pref of familyDeleted) {
        await savePreferenceHistory({
          preferences: pref,
          userId,
          memberId: pref.memberId,
          ownerType: "family",
          changedByUserId: userId,
          changeType: "deleted",
        });
      }
      return res.status(200).json({ message: "Primary and family preferences deleted successfully" });
    }

    const deleted = await PrimaryPreference.findOneAndDelete({ userId });
    if (deleted) {
      await savePreferenceHistory({
        preferences: deleted,
        userId,
        ownerType: "primary",
        changedByUserId: userId,
        changeType: "deleted",
      });
    }
    res.status(200).json({ message: "Primary user preferences deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: "Server error while deleting preferences", error: error.message });
  }
});


app.post("/api/preferences/fix-family-usernames/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const primaryUserName = user.fullName || user.email || "Primary User";

    const result = await FamilyPreference.updateMany(
      { userId },
      { $set: { userName: primaryUserName, preferenceOwnerType: "family" } }
    );

    res.status(200).json({
      message: "Family preference userName fixed to primary user name",
      primaryUserName,
      modifiedCount: result.modifiedCount,
      matchedCount: result.matchedCount,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while fixing family preference usernames",
      error: error.message,
    });
  }
});

const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;
const GOOGLE_CX = process.env.GOOGLE_CX;

app.get("/api/ingredient-google-info", async (req, res) => {
  try {
    const ingredient = String(req.query.ingredient || "").trim();

    if (!ingredient) {
      return res.status(400).json({
        success: false,
        message: "Ingredient is required",
      });
    }

    const query = `${ingredient} food ingredient health information nutrition allergy additive`;

    const googleUrl = "https://www.googleapis.com/customsearch/v1";

    const response = await axios.get(googleUrl, {
      params: {
        key: GOOGLE_API_KEY,
        cx: GOOGLE_CX,
        q: query,
        num: 3,
        safe: "active",
      },
      timeout: 8000,
    });

    const items = response.data.items || [];

    const sentences = items
      .map((item) => item.snippet)
      .filter(Boolean)
      .slice(0, 3);

    return res.json({
      success: true,
      ingredient,
      title: items[0]?.title || ingredient,
      sentences,
      source: items[0]?.link || "",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Could not fetch ingredient information from Google.",
    });
  }
});







const normalizeText = (value) => String(value || "").toLowerCase().trim();

const extractProductIngredients = (body) => {
  const extracted = cleanOcrIngredients(body);
  return extracted.ingredients;
};

const importanceWeight = (importance) => {
  const value = normalizeText(importance);
  if (value.includes("severe")) return 35;
  if (value.includes("essential")) return 30;
  if (value.includes("preferred")) return 18;
  if (value.includes("nice")) return 10;
  return 15;
};

const combinePreferenceItems = (mainList, customList) => [
  ...toStringArray(mainList),
  ...toStringArray(customList),
];

const summarizePreferences = (preferences) => {
  if (!preferences) return [];
  const diets = combinePreferenceItems(preferences.diets, preferences.customDiets);
  const dietary = diets.filter((item) => !normalizeText(item).includes("halal"));
  const religious = diets.filter((item) => normalizeText(item).includes("halal"));
  const restrictions = [
    ...combinePreferenceItems(preferences.allergens, preferences.customAllergens),
    ...combinePreferenceItems(preferences.additives, preferences.customAdditives),
    ...combinePreferenceItems(preferences.ingredients, preferences.customIngredients),
    ...combinePreferenceItems(preferences.avoidedIngredients, preferences.customAvoidedIngredients),
  ];
  return [
    ["Dietary Preferences", dietary, "Weighted"],
    ["Health Goals", combinePreferenceItems(preferences.nutritions, preferences.customNutritions), "Weighted"],
    ["Allergies & Restrictions", restrictions, "Safety first"],
    ["Religious Preferences", religious, "Safety first"],
  ]
    .filter(([, items]) => items.length > 0)
    .map(([category, items, importance]) => ({ category, items, importance }));
};

const findMatches = (ingredients, preferenceItems) => {
  const matches = [];

  for (const pref of preferenceItems) {
    const cleanPref = normalizeText(pref);
    if (!cleanPref) continue;

    for (const ingredient of ingredients) {
      const cleanIngredient = normalizeText(ingredient);
      if (!cleanIngredient) continue;

      if (cleanIngredient.includes(cleanPref) || cleanPref.includes(cleanIngredient)) {
        matches.push({ preference: pref, ingredient });
        break;
      }
    }
  }

  return matches;
};

const allPreferenceTerms = (preferences) => {
  if (!preferences) return [];
  return [
    ...combinePreferenceItems(preferences.allergens, preferences.customAllergens),
    ...combinePreferenceItems(preferences.additives, preferences.customAdditives),
    ...combinePreferenceItems(preferences.diets, preferences.customDiets),
    ...combinePreferenceItems(preferences.ingredients, preferences.customIngredients),
    ...combinePreferenceItems(preferences.nutritions, preferences.customNutritions),
    ...combinePreferenceItems(preferences.avoidedIngredients, preferences.customAvoidedIngredients),
  ].map(normalizeText);
};

const preferenceProfile = (preferences) => {
  const text = allPreferenceTerms(preferences).join(" ");
  const has = (...patterns) => patterns.some((pattern) => text.includes(pattern));
  return {
    lowSugar: has("low sugar", "no sugar", "no added sugar", "sugar free", "avoid sugar", "diabetes", "diabetic"),
    lowCarb: has("low carb", "keto"),
    lowSodium: has("low sodium", "low salt", "avoid salt", "blood pressure", "hypertension"),
    lowCalorie: has("low calorie", "low calories", "calorie deficit", "weight loss", "lose weight"),
    lowFat: has("low fat", "heart", "cholesterol", "avoid fat", "trans fat", "saturated fat"),
    highProtein: has("high protein", "protein rich", "gym", "muscle"),
    highFiber: has("high fiber", "high fibre", "fiber rich", "fibre rich", "whole grain"),
    halalRequired: has("halal"),
  };
};

const addNutritionFlag = (flags, reasons, positiveNotes, condition, flag) => {
  if (!condition) return;
  flags.push(flag);
  if (flag.severity === "positive") {
    positiveNotes.push(flag.message);
  } else {
    reasons.push(flag.message);
  }
};

const analyzeNutritionForPreferences = (nutrition, preferences) => {
  const n = nutrition || {};
  const profile = preferenceProfile(preferences);
  const reasons = [];
  const positiveNotes = [];
  const flags = [];
  let score = n.available ? 100 : 72;

  if (!n.available) {
    reasons.push("Nutrition values were not found, so the score uses ingredient safety and product category only.");
    return {
      score,
      status: "Nutrition data limited",
      reasons,
      positiveNotes,
      flags,
      parsed: n,
    };
  }

  const beverage = n.unit === "ml" || n.basisUnit === "ml";
  const caloriesHigh = beverage ? 80 : 450;
  const caloriesModerate = beverage ? 45 : 250;
  const sugarHigh = beverage ? 11.25 : 22.5;
  const sugarModerate = beverage ? 2.5 : 5;

  if (typeof n.caloriesPer100 === "number") {
    if (n.caloriesPer100 > caloriesHigh) {
      score -= profile.lowCalorie ? 30 : 16;
      addNutritionFlag(flags, reasons, positiveNotes, true, {
        key: "calories",
        severity: "warning",
        message: `High energy value (${Math.round(n.caloriesPer100)} kcal per 100 ${beverage ? "ml" : "g"}).`,
      });
    } else if (n.caloriesPer100 > caloriesModerate) {
      score -= profile.lowCalorie ? 16 : 7;
      addNutritionFlag(flags, reasons, positiveNotes, true, {
        key: "calories",
        severity: "moderate",
        message: `Moderate energy value (${Math.round(n.caloriesPer100)} kcal per 100 ${beverage ? "ml" : "g"}).`,
      });
    } else {
      score += profile.lowCalorie ? 4 : 0;
      addNutritionFlag(flags, reasons, positiveNotes, profile.lowCalorie, {
        key: "calories",
        severity: "positive",
        message: "Calories are a good fit for your low-calorie goal.",
      });
    }
  }

  if (typeof n.sugarsGPer100 === "number") {
    if (n.sugarsGPer100 > sugarHigh) {
      score -= profile.lowSugar ? 38 : 22;
      addNutritionFlag(flags, reasons, positiveNotes, true, {
        key: "sugar",
        severity: "warning",
        message: `High sugar level (${roundNumber(n.sugarsGPer100, 1)} g per 100 ${beverage ? "ml" : "g"}).`,
      });
    } else if (n.sugarsGPer100 > sugarModerate) {
      score -= profile.lowSugar ? 22 : 9;
      addNutritionFlag(flags, reasons, positiveNotes, true, {
        key: "sugar",
        severity: "moderate",
        message: `Moderate sugar level (${roundNumber(n.sugarsGPer100, 1)} g per 100 ${beverage ? "ml" : "g"}).`,
      });
    } else {
      score += profile.lowSugar ? 6 : 0;
      addNutritionFlag(flags, reasons, positiveNotes, profile.lowSugar, {
        key: "sugar",
        severity: "positive",
        message: "Sugar level matches your low-sugar preference.",
      });
    }
  }

  if (profile.lowCarb && typeof n.carbohydrateGPer100 === "number") {
    if (n.carbohydrateGPer100 > 50) {
      score -= 24;
      reasons.push(`High carbohydrate level (${roundNumber(n.carbohydrateGPer100, 1)} g per 100 g/ml).`);
    } else if (n.carbohydrateGPer100 > 20) {
      score -= 12;
      reasons.push(`Moderate carbohydrate level (${roundNumber(n.carbohydrateGPer100, 1)} g per 100 g/ml).`);
    } else {
      score += 5;
      positiveNotes.push("Carbohydrate level matches your low-carb preference.");
    }
  }

  if (typeof n.sodiumMgPer100 === "number") {
    if (n.sodiumMgPer100 > 600) {
      score -= profile.lowSodium ? 32 : 18;
      addNutritionFlag(flags, reasons, positiveNotes, true, {
        key: "sodium",
        severity: "warning",
        message: `High sodium level (${Math.round(n.sodiumMgPer100)} mg per 100 g/ml).`,
      });
    } else if (n.sodiumMgPer100 > 120) {
      score -= profile.lowSodium ? 16 : 7;
      addNutritionFlag(flags, reasons, positiveNotes, true, {
        key: "sodium",
        severity: "moderate",
        message: `Moderate sodium level (${Math.round(n.sodiumMgPer100)} mg per 100 g/ml).`,
      });
    } else {
      score += profile.lowSodium ? 5 : 0;
      addNutritionFlag(flags, reasons, positiveNotes, profile.lowSodium, {
        key: "sodium",
        severity: "positive",
        message: "Sodium is low enough for your salt or blood-pressure preference.",
      });
    }
  }

  if (typeof n.saturatedFatGPer100 === "number") {
    if (n.saturatedFatGPer100 > 5) {
      score -= profile.lowFat ? 28 : 15;
      reasons.push(`High saturated fat (${roundNumber(n.saturatedFatGPer100, 1)} g per 100 g/ml).`);
    } else if (n.saturatedFatGPer100 > 1.5) {
      score -= profile.lowFat ? 14 : 6;
      reasons.push(`Moderate saturated fat (${roundNumber(n.saturatedFatGPer100, 1)} g per 100 g/ml).`);
    }
  } else if (typeof n.fatGPer100 === "number" && n.fatGPer100 > 17.5) {
    score -= profile.lowFat ? 20 : 10;
    reasons.push(`High total fat (${roundNumber(n.fatGPer100, 1)} g per 100 g/ml).`);
  }

  if (profile.highProtein) {
    if ((n.proteinGPer100 || 0) >= 8) {
      score += 8;
      positiveNotes.push("Protein level supports your high-protein goal.");
    } else {
      score -= 10;
      reasons.push("Protein is low for your high-protein goal.");
    }
  }

  if (profile.highFiber) {
    if ((n.fiberGPer100 || 0) >= 3) {
      score += 8;
      positiveNotes.push("Fiber level supports your high-fiber goal.");
    } else {
      score -= 8;
      reasons.push("Fiber is low for your high-fiber goal.");
    }
  }

  score = Math.max(0, Math.min(100, Math.round(score)));
  const status = score >= 78
    ? "Strong nutrition fit"
    : score >= 58
      ? "Moderate nutrition fit"
      : "Poor nutrition fit";

  if (positiveNotes.length === 0 && reasons.length === 0) {
    positiveNotes.push("Nutrition values do not show a major conflict with your saved goals.");
  }

  return {
    score,
    status,
    reasons,
    positiveNotes,
    flags,
    parsed: n,
  };
};

const analyzeForPerson = ({ personName, ownerType, preferences, member }) => {
  const ingredients = member?.__ingredients || [];
  const healthConditions = toStringArray(member?.healthConditions || []);

  if (!preferences) {
    return {
      personName,
      ownerType,
      memberId: member?._id || null,
      status: "No Preferences Set",
      recommendation: "No preferences are saved, so this recommendation is based on ingredient safety only.",
      score: 100,
      riskLevel: "Unknown",
      isRecommended: true,
      matchedIssues: [],
      positiveNotes: ["No preference conflicts found because preferences are not set."],
      healthConditions,
    };
  }

  let score = 100;
  const matchedIssues = [];
  const positiveNotes = [];

  const categories = [
    {
      label: "Allergen",
      items: combinePreferenceItems(preferences.allergens, preferences.customAllergens),
      importance: preferences.allergenImportance,
      message: "This product contains an allergen selected in your profile.",
      penalty: 45,
    },
    {
      label: "Restriction",
      items: [
        ...combinePreferenceItems(preferences.additives, preferences.customAdditives),
        ...combinePreferenceItems(preferences.ingredients, preferences.customIngredients),
        ...combinePreferenceItems(preferences.avoidedIngredients, preferences.customAvoidedIngredients),
      ],
      importance: preferences.ingredientImportance,
      message: "This product contains an ingredient or additive you selected to avoid.",
      penalty: 18,
    },
  ];

  for (const category of categories) {
    const matches = findMatches(ingredients, category.items);
    if (matches.length === 0) continue;

    const penalty = category.penalty * matches.length;
    score -= penalty;

    matchedIssues.push({
      category: category.label,
      importance: category.importance || "Preferred",
      message: category.message,
      matches,
      preference: matches[0]?.preference || category.label,
      reason: `You selected ${matches[0]?.preference || category.label}, and the ingredient list contains ${matches[0]?.ingredient || "a matching ingredient"}.`,
      severity: category.label === "Allergen" ? "critical" : "moderate",
      penalty,
    });
  }

  for (const condition of healthConditions) {
    const c = normalizeText(condition);
    if (!c) continue;

    const conditionKeywords = [];
    if (c.includes("diabetes") || c.includes("sugar")) conditionKeywords.push("sugar", "glucose", "syrup", "fructose");
    if (c.includes("blood pressure") || c.includes("hypertension")) conditionKeywords.push("salt", "sodium");
    if (c.includes("cholesterol") || c.includes("heart")) conditionKeywords.push("palm oil", "hydrogenated", "trans fat");

    const matches = findMatches(ingredients, conditionKeywords);
    if (matches.length > 0) {
      score -= 15 * matches.length;
      matchedIssues.push({
        category: "Health Condition",
        importance: "Essential",
        message: `Extra caution for ${condition}.`,
        matches,
      });
    }
  }

  score = Math.max(0, Math.min(100, score));

  let riskLevel = "Low";
  let status = "Recommended";
  let recommendation = "This product looks suitable based on saved preferences.";
  let isRecommended = true;

  if (score < 55) {
    riskLevel = "High";
    status = "Not Recommended";
    const firstIssue = matchedIssues[0];
    recommendation = firstIssue
      ? `Not recommended because you selected ${firstIssue.preference}. ${firstIssue.reason}`
      : "This product is not recommended because it conflicts with your saved safety preferences.";
    isRecommended = false;
  } else if (score < 72) {
    riskLevel = "Medium";
    status = "Recommended With Caution";
    recommendation = "This product can still be considered, but it has a moderate conflict with your preferences.";
  } else if (matchedIssues.length > 0) {
    riskLevel = "Low to Medium";
    status = "Mostly Suitable";
    recommendation = "This product is mostly suitable, but there are minor preference matches to review.";
  }

  if (matchedIssues.length === 0) {
    positiveNotes.push("No saved allergens, additives, ingredients, diets, or nutrition conflicts were detected.");
  }

  return {
    personName,
    ownerType,
    memberId: member?._id || null,
    status,
    recommendation,
    score,
    riskLevel,
    isRecommended,
    matchedIssues,
    preferenceMatches: matchedIssues.length === 0
      ? [{ preference: "Ingredient restrictions", category: "Safety", reason: "No selected ingredient restriction was detected." }]
      : [],
    preferenceConflicts: matchedIssues,
    positiveNotes,
    healthConditions,
  };
};

const analyzeIngredientsForPreferences = ({
  ingredients,
  preferences,
  personName,
  product = null,
  nutrition = null,
}) => {
  const details = buildIngredientDetails(ingredients);
  const allergens = detectAllergensFromKnowledge(ingredients);
  const halal = resolveProductHalalSummary(product, details);
  const harmful = details.filter((item) => item.safetyStatus === "Harmful");
  const moderate = details.filter((item) => item.safetyStatus === "Moderate");
  const nutritionAnalysis = analyzeNutritionForPreferences(nutrition, preferences);
  const matches = [];
  const conflicts = [];

  const addMatch = (preference, category, reason) => {
    if (matches.some((item) => item.preference === preference && item.reason === reason)) return;
    matches.push({ preference, category, reason, impact: "match" });
  };
  const addConflict = (
    preference,
    category,
    reason,
    severity = "moderate",
    penalty = 14,
    critical = false
  ) => {
    if (conflicts.some((item) => item.preference === preference && item.reason === reason)) return;
    conflicts.push({
      preference,
      category,
      reason,
      severity,
      penalty,
      critical,
      impact: "conflict",
    });
  };

  const selectedDiets = preferences
    ? combinePreferenceItems(preferences.diets, preferences.customDiets)
    : [];
  const selectedGoals = preferences
    ? combinePreferenceItems(preferences.nutritions, preferences.customNutritions)
    : [];
  const selectedAllergens = preferences
    ? combinePreferenceItems(preferences.allergens, preferences.customAllergens)
    : [];
  const selectedRestrictions = preferences
    ? [
        ...combinePreferenceItems(preferences.additives, preferences.customAdditives),
        ...combinePreferenceItems(preferences.ingredients, preferences.customIngredients),
        ...combinePreferenceItems(preferences.avoidedIngredients, preferences.customAvoidedIngredients),
      ]
    : [];
  const selectedPreferenceCount =
    selectedDiets.length +
    selectedGoals.length +
    selectedAllergens.length +
    selectedRestrictions.length;

  const searchableText = normalizeMatchText(
    [
      ...ingredients,
      ...details.flatMap((item) => [
        item.name,
        item.category,
        item.purpose,
        ...toStringArray(item.eCodes),
      ]),
    ]
      .filter(Boolean)
      .join(" ")
  );
  const containsAny = (patterns) =>
    patterns.some((pattern) => searchableText.includes(normalizeMatchText(pattern)));

  const allergenMatches = allergens.filter((item) =>
    selectedAllergens.some((selected) => {
      const cleanSelected = normalizeMatchText(selected);
      return (
        normalizeMatchText(item.allergen).includes(cleanSelected) ||
        cleanSelected.includes(normalizeMatchText(item.allergen)) ||
        item.triggers.some((trigger) =>
          normalizeMatchText(trigger).includes(cleanSelected)
        )
      );
    })
  );
  for (const selected of selectedAllergens) {
    const detected = allergenMatches.find((item) => {
      const cleanSelected = normalizeMatchText(selected);
      return (
        normalizeMatchText(item.allergen).includes(cleanSelected) ||
        cleanSelected.includes(normalizeMatchText(item.allergen))
      );
    });
    if (detected) {
      addConflict(
        selected,
        "Allergies & Restrictions",
        `The label contains ${detected.triggers.slice(0, 3).join(", ") || detected.allergen}.`,
        "critical",
        55,
        true
      );
    } else {
      addMatch(
        selected,
        "Allergies & Restrictions",
        `No ${selected} allergen was detected in the available label.`
      );
    }
  }

  const evaluateDiet = (diet) => {
    const key = normalizeText(diet);
    if (key.includes("halal")) {
      if (halal.status === "Halal") {
        addMatch("Halal", "Religious Preferences", "The ingredient and product review is halal.");
      } else if (halal.status === "Haram") {
        addConflict(
          "Halal",
          "Religious Preferences",
          "The halal analysis found a haram ingredient or product marker.",
          "critical",
          60,
          true
        );
      } else {
        addConflict(
          "Halal",
          "Religious Preferences",
          "One or more ingredient sources still require halal verification.",
          "moderate",
          14
        );
      }
      return;
    }

    if (key.includes("vegan")) {
      const animalIngredients = [
        "milk", "lactose", "whey", "casein", "butter", "cheese", "cream",
        "egg", "albumen", "gelatin", "gelatine", "meat", "chicken", "beef",
        "fish", "shellfish", "honey",
      ];
      containsAny(animalIngredients)
        ? addConflict(
            "Vegan",
            "Dietary Preferences",
            "Animal-derived or animal-associated ingredients were detected.",
            "major",
            35
          )
        : addMatch("Vegan", "Dietary Preferences", "No obvious animal-derived ingredient was detected.");
      return;
    }

    if (key.includes("vegetarian")) {
      const meatIngredients = [
        "meat", "chicken", "beef", "mutton", "pork", "fish", "shellfish",
        "gelatin", "gelatine",
      ];
      containsAny(meatIngredients)
        ? addConflict(
            "Vegetarian",
            "Dietary Preferences",
            "A meat, fish, or gelatin-related ingredient was detected.",
            "major",
            35
          )
        : addMatch("Vegetarian", "Dietary Preferences", "No meat or fish ingredient was detected.");
      return;
    }

    if (key.includes("gluten")) {
      const glutenIngredients = ["wheat", "gluten", "barley", "rye", "malt", "semolina"];
      containsAny(glutenIngredients)
        ? addConflict(
            "Gluten Free",
            "Dietary Preferences",
            "A wheat or gluten-containing ingredient was detected.",
            "major",
            35
          )
        : addMatch("Gluten Free", "Dietary Preferences", "No obvious gluten ingredient was detected.");
      return;
    }

    if (key.includes("keto")) {
      if (!nutrition?.available || typeof nutrition.carbohydrateGPer100 !== "number") {
        addConflict(
          "Keto",
          "Dietary Preferences",
          "Carbohydrate values are unavailable, so keto suitability could not be verified.",
          "unverified",
          4
        );
      } else if (nutrition.carbohydrateGPer100 <= 20) {
        addMatch(
          "Keto",
          "Dietary Preferences",
          `Carbohydrates are ${roundNumber(nutrition.carbohydrateGPer100, 1)} g per 100 g/ml.`
        );
      } else {
        addConflict(
          "Keto",
          "Dietary Preferences",
          `Carbohydrates are ${roundNumber(nutrition.carbohydrateGPer100, 1)} g per 100 g/ml.`,
          nutrition.carbohydrateGPer100 > 50 ? "major" : "moderate",
          nutrition.carbohydrateGPer100 > 50 ? 30 : 14
        );
      }
    }
  };
  selectedDiets.forEach(evaluateDiet);

  const unavailableGoal = (goal) =>
    addConflict(
      goal,
      "Health Goals",
      `Nutrition values are unavailable, so ${goal} could not be verified.`,
      "unverified",
      3
    );
  const beverage = nutrition?.unit === "ml" || nutrition?.basisUnit === "ml";
  const sugar = nutrition?.sugarsGPer100;
  const sodium = nutrition?.sodiumMgPer100;
  const calories = nutrition?.caloriesPer100;
  const fat = nutrition?.fatGPer100;
  const saturatedFat = nutrition?.saturatedFatGPer100;
  const protein = nutrition?.proteinGPer100;
  const fiber = nutrition?.fiberGPer100;

  const evaluateGoal = (goal) => {
    const key = normalizeText(goal);
    if (key.includes("low sugar") || key.includes("diabetic")) {
      if (!nutrition?.available || typeof sugar !== "number") return unavailableGoal(goal);
      const lowLimit = beverage ? 2.5 : 5;
      const highLimit = beverage ? 11.25 : 22.5;
      if (sugar <= lowLimit) {
        addMatch(goal, "Health Goals", `Sugar is low at ${roundNumber(sugar, 1)} g per 100 g/ml.`);
      } else {
        addConflict(
          goal,
          "Health Goals",
          `Sugar is ${roundNumber(sugar, 1)} g per 100 g/ml, above your selected target.`,
          sugar > highLimit ? "major" : "moderate",
          sugar > highLimit ? 30 : 14
        );
      }
      return;
    }
    if (key.includes("low sodium")) {
      if (!nutrition?.available || typeof sodium !== "number") return unavailableGoal(goal);
      if (sodium <= 120) {
        addMatch(goal, "Health Goals", `Sodium is low at ${Math.round(sodium)} mg per 100 g/ml.`);
      } else {
        addConflict(
          goal,
          "Health Goals",
          `Sodium is ${Math.round(sodium)} mg per 100 g/ml, above your selected limit.`,
          sodium > 600 ? "major" : "moderate",
          sodium > 600 ? 30 : 14
        );
      }
      return;
    }
    if (key.includes("low calorie") || key.includes("weight loss")) {
      if (!nutrition?.available || typeof calories !== "number") return unavailableGoal(goal);
      const lowLimit = beverage ? 45 : 250;
      const highLimit = beverage ? 80 : 450;
      if (calories <= lowLimit) {
        addMatch(goal, "Health Goals", `Calories are ${Math.round(calories)} kcal per 100 g/ml.`);
      } else {
        addConflict(
          goal,
          "Health Goals",
          `Calories are ${Math.round(calories)} kcal per 100 g/ml.`,
          calories > highLimit ? "major" : "moderate",
          calories > highLimit ? 26 : 12
        );
      }
      return;
    }
    if (key.includes("low fat") || key.includes("heart")) {
      if (!nutrition?.available || (typeof fat !== "number" && typeof saturatedFat !== "number")) {
        return unavailableGoal(goal);
      }
      const highFat = (fat || 0) > 17.5 || (saturatedFat || 0) > 5;
      const moderateFat = (fat || 0) > 8 || (saturatedFat || 0) > 1.5;
      if (!moderateFat) {
        addMatch(goal, "Health Goals", "Fat values fit your selected target.");
      } else {
        addConflict(
          goal,
          "Health Goals",
          `Fat is ${roundNumber(fat || 0, 1)} g and saturated fat is ${roundNumber(saturatedFat || 0, 1)} g per 100 g/ml.`,
          highFat ? "major" : "moderate",
          highFat ? 28 : 13
        );
      }
      return;
    }
    if (key.includes("high protein")) {
      if (!nutrition?.available || typeof protein !== "number") return unavailableGoal(goal);
      protein >= 8
        ? addMatch(goal, "Health Goals", `Protein is ${roundNumber(protein, 1)} g per 100 g/ml.`)
        : addConflict(
            goal,
            "Health Goals",
            `Protein is only ${roundNumber(protein, 1)} g per 100 g/ml.`,
            "moderate",
            12
          );
      return;
    }
    if (key.includes("high fiber") || key.includes("high fibre")) {
      if (!nutrition?.available || typeof fiber !== "number") return unavailableGoal(goal);
      fiber >= 3
        ? addMatch(goal, "Health Goals", `Fiber is ${roundNumber(fiber, 1)} g per 100 g/ml.`)
        : addConflict(
            goal,
            "Health Goals",
            `Fiber is only ${roundNumber(fiber, 1)} g per 100 g/ml.`,
            "moderate",
            10
          );
    }
  };
  selectedGoals.forEach(evaluateGoal);

  const restrictionPatterns = (restriction) => {
    const key = normalizeText(restriction);
    if (key.includes("msg")) return ["monosodium glutamate", "msg", "e621"];
    if (key.includes("artificial color") || key.includes("artificial colour")) {
      return ["artificial color", "artificial colour", "colorant", "colouring"];
    }
    if (key.includes("preservative")) return ["preservative"];
    if (key.includes("artificial sweetener")) {
      return ["aspartame", "sucralose", "saccharin", "acesulfame", "sweetener"];
    }
    if (key.includes("hydrogenated")) return ["hydrogenated oil", "hydrogenated fat", "trans fat"];
    if (key.includes("added sugar")) {
      return ["sugar", "corn syrup", "glucose syrup", "fructose", "dextrose", "invert syrup"];
    }
    return [restriction];
  };
  for (const restriction of selectedRestrictions) {
    const patterns = restrictionPatterns(restriction);
    const found = patterns.find((pattern) => containsAny([pattern]));
    if (found) {
      addConflict(
        restriction,
        "Allergies & Restrictions",
        `The ingredient analysis found ${found}.`,
        "moderate",
        16
      );
    } else {
      addMatch(
        restriction,
        "Allergies & Restrictions",
        `No matching ${restriction.replace(/^no\s+/i, "")} was detected.`
      );
    }
  }

  for (const item of harmful) {
    addConflict(
      "Ingredient Safety",
      "Product Safety",
      `${item.name} is classified as harmful or restricted.`,
      "major",
      30
    );
  }

  let score = 82;
  score += Math.min(12, matches.length * 3);
  score -= conflicts.reduce((total, item) => total + item.penalty, 0);
  score -= Math.min(10, moderate.length * 2);
  score = Math.max(0, Math.min(100, Math.round(score)));

  const hasCriticalConflict = conflicts.some((item) => item.critical);
  const isRecommended = !hasCriticalConflict && score >= 55;
  const status = !isRecommended
    ? "Not Recommended"
    : score >= 78 && conflicts.length === 0
      ? "Recommended"
      : "Recommended With Caution";
  const riskLevel = hasCriticalConflict || score < 55
    ? "High"
    : conflicts.length > 0
      ? "Medium"
      : "Low";

  let recommendation;
  if (!isRecommended) {
    const first = conflicts[0];
    recommendation = first
      ? first.category === "Product Safety"
        ? `Not recommended because the ingredient safety review found a serious issue. ${first.reason}`
        : `Not recommended because you selected ${first.preference}. ${first.reason}`
      : "Not recommended because the product has a significant safety conflict.";
  } else if (conflicts.length > 0) {
    const first = conflicts[0];
    recommendation =
      `Recommended with caution. It matches ${matches.length} selected preference${matches.length === 1 ? "" : "s"}, ` +
      `but ${first.preference} needs attention: ${first.reason}`;
  } else if (matches.length > 0) {
    recommendation =
      `Recommended because it matches ${matches.map((item) => item.preference).slice(0, 3).join(", ")}.`;
  } else {
    recommendation =
      "Recommended based on the available ingredient, nutrition, and product safety information.";
  }

  return {
    personName,
    ownerType: "primary",
    memberId: null,
    score,
    isRecommended,
    status,
    riskLevel,
    recommendation,
    matchedIssues: conflicts,
    preferenceMatches: matches,
    preferenceConflicts: conflicts,
    positiveNotes: matches.map((item) => `${item.preference}: ${item.reason}`),
    additionalReasons: conflicts.map((item) => `${item.preference}: ${item.reason}`),
    decisionSummary: {
      matches: matches.map((item) => item.preference),
      conflicts: conflicts.map((item) => item.preference),
      selectedPreferenceCount,
      matchedCount: matches.length,
      conflictCount: conflicts.length,
      threshold: 55,
      method: "Weighted preference compatibility",
    },
    halal,
    allergenMatches,
    nutritionAnalysis,
    ingredientStatusCounts: {
      safe: details.filter((item) => item.safetyStatus === "Safe").length,
      moderate: moderate.length,
      harmful: harmful.length,
    },
  };
};

const PRODUCT_FAMILY_TERMS = [
  "rice", "basmati", "biscuit", "biscuits", "cookie", "cookies", "chips", "nimko",
  "noodle", "noodles", "pasta", "macaroni", "milk", "yogurt", "juice", "cola",
  "drink", "water", "tea", "coffee", "chicken", "nugget", "nuggets", "kabab",
  "kebabs", "patty", "patties", "flour", "atta", "sugar", "salt", "oil",
  "ghee", "masala", "spice", "ketchup", "sauce", "jam", "chocolate", "cake",
  "rusk", "cereal", "oats", "honey", "cream", "cheese", "butter", "custard",
  "jelly", "pickle", "achar", "beans", "corn", "lentil", "daal", "dal",
];

const GENERIC_RECIPE_FAMILY_TERMS = new Set(["sugar", "salt", "oil", "water", "flour"]);

const inferProductFamilyTokens = (product, ingredients = []) => {
  const productText = normalizeMatchText([
    product?.["Brand/Product"],
    product?.Variant,
    product?.["Sub Category"],
    product?.Category,
  ].filter(Boolean).join(" "));
  const ingredientText = normalizeMatchText([
    ...ingredients,
  ].filter(Boolean).join(" "));
  return [...new Set(PRODUCT_FAMILY_TERMS
    .filter((term) => {
      const singular = term.replace(/s$/, "");
      const pattern = new RegExp(`\\b${singular}s?\\b`, "i");
      return pattern.test(productText) ||
        (!GENERIC_RECIPE_FAMILY_TERMS.has(singular) && pattern.test(ingredientText));
    })
    .map((term) => term.replace(/s$/, "")))];
};

app.post("/api/recommend-product", auth, async (req, res) => {
  try {
    const { userId, scanHistoryId, productName } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "userId is required" });
    }

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID", receivedUserId: userId });
    }

    const user = await User.findById(userId).select("_id fullName email");
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    let ingredients = extractProductIngredients(req.body);
    let scanResult = req.body.scanResult && typeof req.body.scanResult === "object" ? req.body.scanResult : {};

    let scanHistory = null;
    if (scanHistoryId && isValidObjectId(scanHistoryId)) {
      scanHistory = await ScanHistory.findOne({ _id: scanHistoryId, userId }).lean();
      if (scanHistory) {
        if (ingredients.length === 0) ingredients = scanHistory.ingredients || [];
        if (Object.keys(scanResult).length === 0) scanResult = scanHistory.scanResult || {};
      }
    }

    if (ingredients.length === 0) {
      return res.status(400).json({ message: "No product ingredients found for recommendation" });
    }

    const primaryPreferences = await PrimaryPreference.findOne({ userId }).lean();
    const familyMembers = await FamilyMember.find({ userId }).sort({ createdAt: 1 }).lean();
    const familyPreferences = await FamilyPreference.find({ userId }).lean();

    const primaryResult = analyzeForPerson({
      personName: user.fullName || user.email || "You",
      ownerType: "primary",
      preferences: primaryPreferences,
      member: { __ingredients: ingredients, healthConditions: [] },
    });

    const familyResults = familyMembers.map((member) => {
      const prefs = familyPreferences.find(
        (p) => String(p.memberId) === String(member._id)
      );

      return analyzeForPerson({
        personName: member.name || "Family Member",
        ownerType: "family",
        preferences: prefs,
        member: { ...member, __ingredients: ingredients },
      });
    });

    const results = {
      primary: primaryResult,
      family: familyResults,
      summary: {
        totalPeopleChecked: 1 + familyResults.length,
        recommendedCount: [primaryResult, ...familyResults].filter((r) => r.isRecommended).length,
        cautionCount: [primaryResult, ...familyResults].filter((r) => !r.isRecommended).length,
      },
    };

    const savedRecommendation = await ProductRecommendation.create({
      userId,
      scanHistoryId: scanHistory?._id || null,
      productName: productName || scanResult.productName || scanResult.product_name || "Scanned Product",
      ingredients,
      scanResult,
      results,
    });

    if (scanHistory?._id) {
      await ScanHistory.findByIdAndUpdate(scanHistory._id, {
        $set: {
          recommendationId: savedRecommendation._id,
          healthInformation: results,
          "scanResult.recommendationId": savedRecommendation._id,
        },
      });
    }

    await logActivity({
      userId,
      action: "recommendation_created",
      entityType: "ProductRecommendation",
      entityId: savedRecommendation._id,
      metadata: {
        scanHistoryId: scanHistory?._id || null,
        productName: savedRecommendation.productName,
        ingredientCount: ingredients.length,
      },
    });

    res.status(200).json({
      message: "AI product recommendation generated successfully",
      collection: "productrecommendations",
      recommendationId: savedRecommendation._id,
      productName: savedRecommendation.productName,
      ingredients,
      results,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while generating product recommendation",
      error: error.message,
    });
  }
});

const recommendDatasetAlternatives = ({
  identifiedProduct,
  scannedIngredients,
  preferences,
  personName,
  limit = 5,
}) => {
  const sourceCategory = normalizeMatchText(identifiedProduct?.Category);
  const sourceSubCategory = normalizeMatchText(identifiedProduct?.["Sub Category"]);
  if (!identifiedProduct || !sourceCategory) return [];

  const trustedCandidates = halalVerifiedProducts
    .filter((product) => {
      return product.product_key !== identifiedProduct.product_key;
    })
    .filter(
      (product) =>
        product.halal_recommendation_eligible === true &&
        splitDatasetIngredients(product).length > 0
    );
  const sameCategoryProducts = trustedCandidates.filter(
    (product) => normalizeMatchText(product.Category) === sourceCategory
  );
  const sourceFamilyTokens = inferProductFamilyTokens(
    identifiedProduct,
    scannedIngredients.length > 0 ? scannedIngredients : splitDatasetIngredients(identifiedProduct)
  );
  const familyMatchedProducts = sameCategoryProducts.filter((product) => {
    const tokens = inferProductFamilyTokens(product, splitDatasetIngredients(product));
    return sourceFamilyTokens.some((token) => tokens.includes(token));
  });
  const candidateProducts =
    sourceFamilyTokens.length > 0 && familyMatchedProducts.length >= Math.min(limit, 3)
      ? familyMatchedProducts
      : sameCategoryProducts;

  return candidateProducts
    .map((product) => {
      const ingredients = splitDatasetIngredients(product);
      const nutrition = getProductNutrition(product);
      const suitability = analyzeIngredientsForPreferences({
        ingredients,
        preferences,
        personName,
        product,
        nutrition,
      });
      const similarity = scoreProductIngredientMatch(scannedIngredients, product);
      const sameSubCategory =
        sourceSubCategory &&
        normalizeMatchText(product["Sub Category"]) === sourceSubCategory;
      const categoryLevel = sameSubCategory ? "Same subcategory" : "Same category";
      const familyOverlap = inferProductFamilyTokens(product, ingredients)
        .filter((token) => sourceFamilyTokens.includes(token)).length;
      const qualityBonus = product.recommendation_data_quality === "High" ? 25 : 0;
      const nutritionScore = suitability.nutritionAnalysis?.score || 60;
      const rankingScore =
        (sameSubCategory ? 2000 : 0) +
        familyOverlap * 700 +
        (suitability.isRecommended ? 1200 : 0) +
        suitability.score * 2 +
        nutritionScore * 3 +
        qualityBonus +
        similarity * 10;
      const whySuggested = [
        `${categoryLevel}: ${product["Sub Category"] || product.Category}.`,
        familyOverlap > 0 ? "Matches the same product family as the scanned item." : "",
        "Treated as halal under the Pakistani-market product policy.",
        `Matches your saved preferences with a ${Math.round(suitability.score)}/100 suitability score.`,
        `Nutrition fit score is ${Math.round(nutritionScore)}/100.`,
        product.recommendation_data_quality === "High"
          ? "Uses a detailed trusted ingredient label."
          : "Ingredient details are limited; review the physical label before purchase.",
        suitability.ingredientStatusCounts.harmful === 0
          ? "No harmful ingredients were identified."
          : "",
        suitability.halal.status === "Halal" ? "Ingredients are marked halal." : "",
      ].filter(Boolean);

      return {
        productName: [product["Brand/Product"], product.Variant]
          .filter(Boolean)
          .join(" - "),
        category: product.Category || "",
        subCategory: product["Sub Category"] || "",
        ingredients,
        nutritionFacts: product["Nutritional Facts"] || "",
        nutrition,
        nutritionAnalysis: suitability.nutritionAnalysis,
        suitability,
        halal: suitability.halal,
        categoryMatch: categoryLevel,
        fullySuitable: suitability.isRecommended,
        dataQuality: product.recommendation_data_quality || "Limited",
        whySuggested,
        rankingScore,
      };
    })
    .sort((a, b) => b.rankingScore - a.rankingScore)
    .slice(0, limit)
    .map(({ rankingScore, ...item }) => item);
};


app.post("/api/analyze-scanned-product", auth, async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId || !isValidObjectId(userId)) {
      return res.status(400).json({ message: "A valid userId is required" });
    }

    const user = await User.findById(userId).select("_id fullName email");
    if (!user) return res.status(404).json({ message: "User not found" });

    const ingredients = extractProductIngredients(req.body);
    if (ingredients.length === 0) {
      return res.status(400).json({ message: "No scanned ingredients were found" });
    }

    const preferences = await PrimaryPreference.findOne({ userId }).lean();
    const identified = identifyDatasetProduct(ingredients);
    const productForPolicy = identified.product || identified.categoryProduct;
    const details = buildIngredientDetails(ingredients);
    const allergens = detectAllergensFromKnowledge(ingredients);
    const halal = resolveProductHalalSummary(productForPolicy, details);
    const nutrition = resolveNutritionForAnalysis({
      scannedNutritionText: req.body.nutritionalFacts || req.body.nutritionFacts,
      matchedProduct: identified.product,
      categoryProduct: identified.categoryProduct,
    });
    const calories = {
      caloriesPer100: nutrition.caloriesPer100,
      method: nutrition.method,
      confidence: nutrition.confidence,
      source: nutrition.source,
      estimated: nutrition.estimated === true,
    };
    const suitability = analyzeIngredientsForPreferences({
      ingredients,
      preferences,
      personName: user.fullName || user.email || "You",
      product: productForPolicy,
      nutrition,
    });
    const alternatives = recommendDatasetAlternatives({
      identifiedProduct: identified.product || identified.categoryProduct,
      scannedIngredients: ingredients,
      preferences,
      personName: user.fullName || user.email || "You",
    });

    const harmfulIngredients = details.filter((item) => item.safetyStatus === "Harmful");
    const moderateIngredients = details.filter((item) => item.safetyStatus === "Moderate");
    const safeIngredients = details.filter((item) => item.safetyStatus === "Safe");

    const productIdentification = {
      identified: identified.identified,
      productName: identified.productName,
      confidence: identified.confidence,
      confidenceLevel: identified.confidenceLevel,
      matchMargin: identified.matchMargin,
      explanation: identified.explanation,
      category: identified.product?.Category || identified.categoryProduct?.Category || "",
      subCategory:
        identified.product?.["Sub Category"] ||
        identified.categoryProduct?.["Sub Category"] ||
        "",
      categoryInferred: !identified.product && Boolean(identified.categoryProduct),
      categoryInferenceConfidence:
        identified.categoryProduct?.categoryInferenceConfidence || null,
      variant: identified.product?.Variant || identified.categoryProduct?.Variant || "",
      halalStatus: halal.status,
      safetyLabel: productForPolicy?.safety_label || "",
    };
    const safetySummary = {
      harmfulCount: harmfulIngredients.length,
      moderateCount: moderateIngredients.length,
      safeCount: safeIngredients.length,
      overallLabel: suitability.isRecommended
        ? (moderateIngredients.length > 0 ? "Moderate" : "Safe")
        : "Not Recommended",
      harmfulIngredients: harmfulIngredients.map((item) => item.name),
      moderateIngredients: moderateIngredients.map((item) => item.name),
      safeIngredients: safeIngredients.map((item) => item.name),
    };
    const datasetMatch = productForPolicy
      ? {
          matchType: identified.product ? "exact_product" : "category_representative",
          ingredients: splitDatasetIngredients(productForPolicy),
          nutritionFacts: productForPolicy["Nutritional Facts"] || "",
          declaredAllergens: productForPolicy.Allergens || "",
        }
      : null;
    const healthInformation = {
      recommendation: suitability.recommendation,
      preferenceIssues: suitability.matchedIssues || [],
      nutritionReasons: suitability.nutritionAnalysis?.reasons || [],
      nutritionPositiveNotes: suitability.nutritionAnalysis?.positiveNotes || [],
      ingredientStatusCounts: suitability.ingredientStatusCounts,
      halal,
      calories,
    };
    const responseData = {
      message: "Scanned product analyzed successfully",
      productIdentification,
      scannedIngredients: ingredients,
      selectedPreferences: summarizePreferences(preferences),
      ingredientDetails: details,
      allergens: {
        detected: allergens,
        preferenceMatches: suitability.allergenMatches,
      },
      halal,
      calories,
      nutrition,
      nutritionAnalysis: suitability.nutritionAnalysis,
      safetySummary,
      suitability: {
        ...suitability,
        preferencesFound: Boolean(preferences),
      },
      alternatives,
      alternativesMessage: alternatives.length > 0
        ? "Alternatives are from the closest matching product category and ranked by your preferences."
        : "No alternative with enough category information was found.",
      datasetMatch,
      healthInformation,
    };

    const auditExtraction = cleanOcrIngredients(req.body);
    let scanHistory = null;
    if (req.body.scanHistoryId && isValidObjectId(req.body.scanHistoryId)) {
      scanHistory = await ScanHistory.findOne({ _id: req.body.scanHistoryId, userId });
    }
    if (!scanHistory) {
      scanHistory = await ScanHistory.create({
        userId,
        userName: user.fullName || "Primary User",
        userEmail: user.email || "",
        rawOcrText: auditExtraction.rawText || req.body.rawOcrText || "",
        ocrValidation: auditExtraction.ocrValidation || {},
        ingredients,
        ingredientCount: ingredients.length,
        scanResult: {
          ...(req.body.scanResult && typeof req.body.scanResult === "object" ? req.body.scanResult : {}),
          rawOcrText: auditExtraction.rawText || req.body.rawOcrText || "",
          extractedIngredients: ingredients,
        },
      });
    }

    let ocrResult = null;
    if (scanHistory.ocrResultId && isValidObjectId(scanHistory.ocrResultId)) {
      ocrResult = await OcrResult.findById(scanHistory.ocrResultId);
    }
    if (!ocrResult) {
      ocrResult = await OcrResult.create({
        userId,
        scanHistoryId: scanHistory._id,
        rawText: auditExtraction.rawText || scanHistory.rawOcrText || req.body.rawOcrText || "",
        extractedIngredients: ingredients,
        ingredientCount: ingredients.length,
        validation: auditExtraction.ocrValidation || scanHistory.ocrValidation || {},
        scanResult: scanHistory.scanResult || {},
        source: "analysis_flow",
      });
      await ScanHistory.findByIdAndUpdate(scanHistory._id, {
        $set: {
          ocrResultId: ocrResult._id,
          "scanResult.ocrResultId": ocrResult._id,
        },
      });
    }

    const savedAnalysis = await ProductAnalysis.create({
      userId,
      scanHistoryId: scanHistory._id,
      ocrResultId: ocrResult?._id || null,
      productName: productIdentification.productName,
      rawOcrText: auditExtraction.rawText || scanHistory.rawOcrText || "",
      ingredients,
      productIdentification,
      ingredientDetails: details,
      allergens: responseData.allergens,
      halal,
      calories,
      nutrition,
      nutritionAnalysis: suitability.nutritionAnalysis,
      safetySummary,
      selectedPreferences: responseData.selectedPreferences,
      suitability: responseData.suitability,
      alternatives,
      datasetMatch,
      healthInformation,
      fullResponse: responseData,
    });

    const savedRecommendation = await ProductRecommendation.create({
      userId,
      scanHistoryId: scanHistory._id,
      productName: productIdentification.productName,
      ingredients,
      scanResult: {
        rawOcrText: auditExtraction.rawText || scanHistory.rawOcrText || "",
        productIdentification,
      },
      results: {
        analysisId: savedAnalysis._id,
        suitability: responseData.suitability,
        alternatives,
        safetySummary,
        halal,
        calories,
        nutritionAnalysis: suitability.nutritionAnalysis,
      },
    });

    savedAnalysis.recommendationId = savedRecommendation._id;
    savedAnalysis.fullResponse = {
      ...responseData,
      analysisId: savedAnalysis._id,
      recommendationId: savedRecommendation._id,
      scanHistoryId: scanHistory._id,
    };
    await savedAnalysis.save();

    const healthReport = await HealthReport.create({
      userId,
      scanHistoryId: scanHistory._id,
      productAnalysisId: savedAnalysis._id,
      recommendationId: savedRecommendation._id,
      productName: productIdentification.productName,
      safetyScore: responseData.suitability?.score || null,
      halal,
      calories,
      ingredientBreakdown: details,
      healthInformation,
      recommendation: responseData.suitability,
      fullReport: responseData,
    });

    await ScanHistory.findByIdAndUpdate(scanHistory._id, {
      $set: {
        productAnalysisId: savedAnalysis._id,
        recommendationId: savedRecommendation._id,
        healthReportId: healthReport._id,
        productResult: productIdentification,
        ingredientDetails: details,
        healthInformation,
        "scanResult.productAnalysisId": savedAnalysis._id,
        "scanResult.recommendationId": savedRecommendation._id,
        "scanResult.productIdentification": productIdentification,
      },
    });

    await logActivity({
      userId,
      action: "scan_analyzed",
      entityType: "ProductAnalysis",
      entityId: savedAnalysis._id,
      metadata: {
        scanHistoryId: scanHistory._id,
        recommendationId: savedRecommendation._id,
        productName: productIdentification.productName,
        halalStatus: halal.status,
        halalConfidence: halal.confidence,
        alternativeCount: alternatives.length,
      },
    });
    await createAppNotification({
      type: "new_recommendation",
      senderUserId: user._id,
      senderName: "CalorieMate",
      recipientUserId: user._id,
      title: "New product recommendation ready",
      body: `${productIdentification.productName} was analyzed with your saved preferences.`,
      payload: {
        scanHistoryId: scanHistory._id,
        analysisId: savedAnalysis._id,
        recommendationId: savedRecommendation._id,
        healthReportId: healthReport._id,
        status: responseData.suitability?.status,
      },
    });

    return res.status(200).json({
      ...responseData,
      analysisId: savedAnalysis._id,
      recommendationId: savedRecommendation._id,
      scanHistoryId: scanHistory._id,
      healthReportId: healthReport._id,
      collection: "productanalyses",
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while analyzing scanned product",
      error: error.message,
    });
  }
});

app.get("/api/recommend-product/history/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Invalid user ID" });
    }

    const recommendations = await ProductRecommendation.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    res.status(200).json({
      message: "Recommendation history fetched successfully",
      count: recommendations.length,
      recommendations,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while fetching recommendation history",
      error: error.message,
    });
  }
});

app.get("/api/product-analysis/history/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Invalid user ID" });

    const analyses = await ProductAnalysis.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    res.status(200).json({
      message: "Product analysis history fetched successfully",
      collection: "productanalyses",
      count: analyses.length,
      analyses,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while fetching product analysis history",
      error: error.message,
    });
  }
});

app.post("/api/product-comparisons", auth, async (req, res) => {
  try {
    const { userId, productA, productB, comparisonResult, preferencesSnapshot, scanHistoryIds } = req.body;
    if (!userId || !isValidObjectId(userId)) {
      return res.status(400).json({ message: "A valid userId is required" });
    }

    const comparison = await ProductComparisonHistory.create({
      userId,
      scanHistoryIds: toStringArray(scanHistoryIds).filter(isValidObjectId),
      productA: productA && typeof productA === "object" ? productA : {},
      productB: productB && typeof productB === "object" ? productB : {},
      comparisonResult: comparisonResult && typeof comparisonResult === "object" ? comparisonResult : {},
      preferencesSnapshot: preferencesSnapshot && typeof preferencesSnapshot === "object" ? preferencesSnapshot : {},
    });

    await logActivity({
      userId,
      action: "product_comparison_saved",
      entityType: "ProductComparisonHistory",
      entityId: comparison._id,
      metadata: {
        productA: comparison.productA?.productName || comparison.productA?.name || "",
        productB: comparison.productB?.productName || comparison.productB?.name || "",
      },
    });

    res.status(201).json({
      message: "Product comparison history saved successfully",
      collection: "productcomparisonhistories",
      comparison,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while saving product comparison history",
      error: error.message,
    });
  }
});

app.get("/api/product-comparisons/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Invalid user ID" });

    const comparisons = await ProductComparisonHistory.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    res.status(200).json({
      message: "Product comparison history fetched successfully",
      collection: "productcomparisonhistories",
      count: comparisons.length,
      comparisons,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while fetching product comparison history",
      error: error.message,
    });
  }
});

app.get("/api/activity-logs/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Invalid user ID" });

    const logs = await ActivityLog.find({ userId })
      .sort({ createdAt: -1 })
      .limit(200)
      .lean();

    res.status(200).json({
      message: "Activity logs fetched successfully",
      collection: "activitylogs",
      count: logs.length,
      logs,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error while fetching activity logs",
      error: error.message,
    });
  }
});

app.get("/api/ocr-results/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Invalid user ID" });

    const results = await OcrResult.find({ userId }).sort({ createdAt: -1 }).limit(200).lean();
    res.status(200).json({
      message: "OCR results fetched successfully",
      collection: "ocrresults",
      count: results.length,
      results,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while fetching OCR results", error: error.message });
  }
});

app.get("/api/preferences/history/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const { memberId } = req.query;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Invalid user ID" });
    if (memberId && !isValidObjectId(memberId)) return res.status(400).json({ message: "Invalid member ID" });

    const filter = { userId };
    if (memberId) filter.memberId = memberId;
    const history = await PreferenceHistory.find(filter).sort({ createdAt: -1 }).limit(100).lean();

    res.status(200).json({
      message: "Preference history fetched successfully",
      collection: "preferencehistories",
      count: history.length,
      history,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while fetching preference history", error: error.message });
  }
});

const notificationTypeForShare = (type) => {
  const map = {
    product: "shared_product",
    recommendation: "shared_recommendation",
    ingredient_warning: "shared_ingredient_warning",
    nutrition_advice: "shared_nutrition_advice",
    health_guide: "shared_health_guide",
  };
  return map[type] || "shared_product";
};

app.post("/api/shared-content", auth, async (req, res) => {
  try {
    const {
      senderUserId,
      recipientUserId,
      recipientEmail,
      memberId,
      type = "product",
      title,
      message,
      payload,
    } = req.body;

    if (!isValidObjectId(senderUserId)) {
      return res.status(400).json({ message: "A valid senderUserId is required" });
    }

    const sender = await User.findById(senderUserId).select("_id fullName email").lean();
    if (!sender) return res.status(404).json({ message: "Sender user not found" });

    let member = null;
    if (memberId && isValidObjectId(memberId)) {
      member = await FamilyMember.findOne({ _id: memberId, userId: senderUserId }).lean();
    }

    const finalRecipientUserId =
      isValidObjectId(recipientUserId)
        ? recipientUserId
        : member?.invitedUserId || null;
    const finalRecipientEmail = normalizeEmail(recipientEmail || member?.invitationEmail || "");

    if (!finalRecipientUserId && !finalRecipientEmail) {
      return res.status(400).json({ message: "Recipient user, email, or connected family member is required" });
    }

    const share = await SharedContent.create({
      senderUserId,
      senderName: sender.fullName || sender.email || "CalorieMate user",
      recipientUserId: finalRecipientUserId,
      recipientEmail: finalRecipientEmail,
      memberId: member?._id || null,
      type,
      title: title || "Shared CalorieMate item",
      message: message || "",
      payload: payload && typeof payload === "object" ? payload : {},
    });

    const notification = await createAppNotification({
      type: notificationTypeForShare(type),
      senderUserId,
      senderName: share.senderName,
      recipientUserId: finalRecipientUserId,
      recipientEmail: finalRecipientEmail,
      memberId: member?._id || null,
      title: share.title,
      body: share.message || `${share.senderName} shared a ${type.replace(/_/g, " ")} with you.`,
      payload: { shareId: share._id, type, ...share.payload },
    });

    if (notification?._id) {
      share.notificationId = notification._id;
      await share.save();
    }

    await logActivity({
      userId: senderUserId,
      action: "shared_content_created",
      entityType: "SharedContent",
      entityId: share._id,
      metadata: { type, recipientUserId: finalRecipientUserId, recipientEmail: finalRecipientEmail },
    });

    res.status(201).json({
      message: "Shared content saved and notification created",
      collection: "sharedcontents",
      share,
      notification,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while sharing content", error: error.message });
  }
});

app.get("/api/shared-content/user/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Invalid user ID" });

    const user = await User.findById(userId).select("_id email").lean();
    if (!user) return res.status(404).json({ message: "User not found" });
    const email = normalizeEmail(user.email);
    const shares = await SharedContent.find({
      $or: [
        { senderUserId: userId },
        { recipientUserId: userId },
        { recipientEmail: email },
      ],
    }).sort({ createdAt: -1 }).lean();

    res.status(200).json({
      message: "Shared content fetched successfully",
      collection: "sharedcontents",
      count: shares.length,
      shares,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while fetching shared content", error: error.message });
  }
});

app.post("/api/product-feedback", auth, async (req, res) => {
  try {
    const { userId, scanHistoryId, productAnalysisId, productName, rating, feedbackType, message, payload } = req.body;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "A valid userId is required" });

    const feedback = await ProductFeedback.create({
      userId,
      scanHistoryId: isValidObjectId(scanHistoryId) ? scanHistoryId : null,
      productAnalysisId: isValidObjectId(productAnalysisId) ? productAnalysisId : null,
      productName: productName || "",
      rating: Number.isFinite(Number(rating)) ? Number(rating) : null,
      feedbackType: feedbackType || "general",
      message: message || "",
      payload: payload && typeof payload === "object" ? payload : {},
    });

    await logActivity({
      userId,
      action: "product_feedback_saved",
      entityType: "ProductFeedback",
      entityId: feedback._id,
      metadata: { productName, rating, feedbackType },
    });

    res.status(201).json({
      message: "Product feedback saved successfully",
      collection: "productfeedbacks",
      feedback,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while saving product feedback", error: error.message });
  }
});

app.get("/api/health-reports/:userId", auth, async (req, res) => {
  try {
    const { userId } = req.params;
    if (!isValidObjectId(userId)) return res.status(400).json({ message: "Invalid user ID" });

    const reports = await HealthReport.find({ userId }).sort({ createdAt: -1 }).limit(200).lean();
    res.status(200).json({
      message: "Health reports fetched successfully",
      collection: "healthreports",
      count: reports.length,
      reports,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error while fetching health reports", error: error.message });
  }
});


app.use((err, req, res, next) => {
  console.error("Unhandled error:", err.stack);
  res.status(500).json({
    message: "Something went wrong!",
    error: err.message,
  });
});

app.use((req, res) => {
  res.status(404).json({
    message: "Route not found",
    path: req.originalUrl,
  });
});




const PORT = process.env.PORT || 9000;

if (require.main === module) {
  server.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = {
  analyzeIngredientsForPreferences,
  buildIngredientDetails,
  calculateHalalSummary,
  classifyIngredientHalal,
  identifyDatasetProduct,
  parseNutritionFacts,
  recommendDatasetAlternatives,
  resolveNutritionForAnalysis,
};
