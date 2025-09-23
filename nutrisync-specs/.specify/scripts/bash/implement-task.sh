#!/bin/bash

# Implementation helper for spec-kit tasks
# Usage: ./implement-task.sh T001

TASK_ID=$1
TASKS_FILE="post-onboarding-windows-tasks.md"
PROGRESS_FILE="post-onboarding-progress.md"

if [ -z "$TASK_ID" ]; then
    echo "Usage: ./implement-task.sh T001"
    exit 1
fi

# Extract task description
TASK=$(grep -A 1 "^\- \[ \] $TASK_ID" $TASKS_FILE | head -1)

if [ -z "$TASK" ]; then
    echo "Task $TASK_ID not found or already completed"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "📋 Implementing Task: $TASK_ID"
echo "═══════════════════════════════════════════════════════"
echo "$TASK"
echo ""
echo "Instructions:"

case $TASK_ID in
    T001)
        echo "1. Open NutriSync/Models/UserProfile.swift"
        echo "2. Add to struct UserProfile:"
        echo "   var firstDayCompleted: Bool = false"
        echo "   var onboardingCompletedAt: Date?"
        ;;
    T002)
        echo "1. Open NutriSync/Services/DataProvider/FirebaseDataProvider.swift"
        echo "2. Update saveUserProfile() to include new fields"
        echo "3. Update getUserProfile() to read new fields"
        ;;
    T003)
        echo "1. Create new file: NutriSync/Models/FirstDayConfiguration.swift"
        echo "2. Add struct with:"
        echo "   - startTime: Date"
        echo "   - remainingHours: Double"
        echo "   - proRatedCalories: Int"
        echo "   - numberOfWindows: Int"
        ;;
    T004)
        echo "1. Create new file: NutriSync/Services/FirstDayWindowService.swift"
        echo "2. Implement protocol FirstDayWindowGenerating"
        echo "3. Add methods from plan.md"
        ;;
    *)
        echo "Implementation steps not defined for $TASK_ID"
        echo "Check post-onboarding-windows-tasks.md for details"
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════"
echo "After completing, mark in progress file and commit:"
echo "git add -A && git commit -m \"feat(first-day): $TASK_ID completed\""