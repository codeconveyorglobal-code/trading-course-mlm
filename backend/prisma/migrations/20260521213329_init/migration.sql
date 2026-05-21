-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "phone" TEXT,
    "role" TEXT NOT NULL DEFAULT 'user',
    "profilePicture" TEXT,
    "referralCode" TEXT NOT NULL,
    "referredBy" TEXT,
    "sponsorId" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isEmailVerified" BOOLEAN NOT NULL DEFAULT false,
    "emailVerificationToken" TEXT,
    "resetPasswordToken" TEXT,
    "resetPasswordExpire" DATETIME,
    "walletBalance" REAL NOT NULL DEFAULT 0,
    "totalEarnings" REAL NOT NULL DEFAULT 0,
    "totalWithdrawn" REAL NOT NULL DEFAULT 0,
    "cryptoWalletAddress" TEXT,
    "rank" TEXT NOT NULL DEFAULT 'Bronze',
    "purchasedCourses" TEXT NOT NULL DEFAULT '[]',
    "kycStatus" TEXT NOT NULL DEFAULT 'pending',
    "kycDocuments" TEXT NOT NULL DEFAULT '[]',
    "lastLogin" DATETIME,
    "joinDate" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "Course" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "shortDescription" TEXT,
    "category" TEXT NOT NULL,
    "level" TEXT NOT NULL DEFAULT 'Beginner',
    "price" REAL NOT NULL,
    "discountPrice" REAL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "thumbnail" TEXT,
    "previewVideo" TEXT,
    "instructorId" TEXT,
    "instructorName" TEXT,
    "materials" TEXT NOT NULL DEFAULT '[]',
    "quizzes" TEXT NOT NULL DEFAULT '[]',
    "tags" TEXT NOT NULL DEFAULT '[]',
    "language" TEXT NOT NULL DEFAULT 'English',
    "duration" TEXT,
    "totalLessons" INTEGER NOT NULL DEFAULT 0,
    "isPublished" BOOLEAN NOT NULL DEFAULT false,
    "isFeatured" BOOLEAN NOT NULL DEFAULT false,
    "isMLMEligible" BOOLEAN NOT NULL DEFAULT true,
    "enrolledCount" INTEGER NOT NULL DEFAULT 0,
    "rating" REAL NOT NULL DEFAULT 0,
    "reviewCount" INTEGER NOT NULL DEFAULT 0,
    "requirements" TEXT NOT NULL DEFAULT '[]',
    "whatYouLearn" TEXT NOT NULL DEFAULT '[]',
    "completionCertificate" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "Enrollment" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "transactionId" TEXT,
    "progress" REAL NOT NULL DEFAULT 0,
    "completedMaterials" TEXT NOT NULL DEFAULT '[]',
    "completedAt" DATETIME,
    "certificateUrl" TEXT,
    "lastAccessedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "Transaction" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "courseId" TEXT,
    "type" TEXT NOT NULL,
    "amount" REAL NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "cryptoCurrency" TEXT,
    "cryptoAmount" REAL,
    "cryptoAddress" TEXT,
    "txHash" TEXT,
    "exchangeRate" REAL,
    "paymentId" TEXT,
    "paymentStatus" TEXT NOT NULL DEFAULT 'waiting',
    "status" TEXT NOT NULL DEFAULT 'pending',
    "description" TEXT,
    "metadata" TEXT,
    "completedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "Commission" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "fromUserId" TEXT NOT NULL,
    "transactionId" TEXT,
    "courseId" TEXT,
    "type" TEXT NOT NULL,
    "level" INTEGER NOT NULL DEFAULT 1,
    "percentage" REAL,
    "baseAmount" REAL NOT NULL,
    "amount" REAL NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "paidAt" DATETIME,
    "paidVia" TEXT,
    "description" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "Withdrawal" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "amount" REAL NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USDT',
    "cryptoAddress" TEXT NOT NULL,
    "network" TEXT,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "txHash" TEXT,
    "adminNote" TEXT,
    "processedAt" DATETIME,
    "processedById" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "MLMNode" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "parentId" TEXT,
    "sponsorId" TEXT,
    "position" TEXT NOT NULL DEFAULT 'left',
    "level" INTEGER NOT NULL DEFAULT 0,
    "leftChildId" TEXT,
    "rightChildId" TEXT,
    "leftVolume" REAL NOT NULL DEFAULT 0,
    "rightVolume" REAL NOT NULL DEFAULT 0,
    "leftCount" INTEGER NOT NULL DEFAULT 0,
    "rightCount" INTEGER NOT NULL DEFAULT 0,
    "leftCarry" REAL NOT NULL DEFAULT 0,
    "rightCarry" REAL NOT NULL DEFAULT 0,
    "totalDirectReferrals" INTEGER NOT NULL DEFAULT 0,
    "totalTeamSize" INTEGER NOT NULL DEFAULT 0,
    "totalEarnings" REAL NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "MLMSettings" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "singleton" BOOLEAN NOT NULL DEFAULT true,
    "directReferralCommission" REAL NOT NULL DEFAULT 10,
    "levelCommissions" TEXT NOT NULL DEFAULT '[]',
    "binaryEnabled" BOOLEAN NOT NULL DEFAULT true,
    "binaryMatchingBonus" REAL NOT NULL DEFAULT 10,
    "binaryWeakLegPercentage" REAL NOT NULL DEFAULT 100,
    "maxBinaryPercentage" REAL NOT NULL DEFAULT 50,
    "rankBonuses" TEXT NOT NULL DEFAULT '[]',
    "minPayout" REAL NOT NULL DEFAULT 50,
    "payoutSchedule" TEXT NOT NULL DEFAULT 'weekly',
    "payoutDay" INTEGER NOT NULL DEFAULT 1,
    "commissionHoldDays" INTEGER NOT NULL DEFAULT 7,
    "commissionCurrency" TEXT NOT NULL DEFAULT 'USDT',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "Quiz" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "courseId" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "questions" TEXT NOT NULL DEFAULT '[]',
    "timeLimit" INTEGER NOT NULL DEFAULT 30,
    "passingScore" REAL NOT NULL DEFAULT 70,
    "totalMarks" REAL NOT NULL DEFAULT 0,
    "attempts" INTEGER NOT NULL DEFAULT 3,
    "isPublished" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "QuizAttempt" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "quizId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "answers" TEXT NOT NULL DEFAULT '[]',
    "score" REAL NOT NULL DEFAULT 0,
    "totalMarks" REAL NOT NULL DEFAULT 0,
    "percentage" REAL NOT NULL DEFAULT 0,
    "passed" BOOLEAN NOT NULL DEFAULT false,
    "timeTaken" INTEGER,
    "completedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "certificateUrl" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_referralCode_key" ON "User"("referralCode");

-- CreateIndex
CREATE UNIQUE INDEX "Course_slug_key" ON "Course"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Enrollment_userId_courseId_key" ON "Enrollment"("userId", "courseId");

-- CreateIndex
CREATE UNIQUE INDEX "Transaction_paymentId_key" ON "Transaction"("paymentId");

-- CreateIndex
CREATE UNIQUE INDEX "MLMNode_userId_key" ON "MLMNode"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "MLMSettings_singleton_key" ON "MLMSettings"("singleton");
