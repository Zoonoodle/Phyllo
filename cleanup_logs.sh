#!/bin/bash

# Script to clean up unnecessary print statements and standardize logging

echo "Cleaning up unnecessary UI logs..."

# Remove simple UI action prints from Nudges
files=(
    "NutriSync/Views/Nudges/Nudges/MissedWindowNudge.swift"
    "NutriSync/Views/Nudges/Nudges/MissedMealsInstructionalNudge.swift"
    "NutriSync/Views/Nudges/Nudges/VoiceInputInstructionalNudge.swift"
    "NutriSync/Views/Nudges/Nudges/VoiceInputTipsNudge.swift"
    "NutriSync/Views/Nudges/Nudges/MorningCheckInNudge.swift"
    "NutriSync/Views/Nudges/Nudges/ActiveWindowNudge.swift"
    "NutriSync/Views/Nudges/Nudges/MealCelebrationNudge.swift"
    "NutriSync/Views/Nudges/Nudges/PostMealCheckInNudge.swift"
    "NutriSync/Views/Nudges/Nudges/FirstTimeTutorialNudge.swift"
    "NutriSync/Views/Nudges/Components/FloatingNudgeCard.swift"
    "NutriSync/Views/Nudges/Components/CoachingCard.swift"
    "NutriSync/Views/Nudges/Components/CompactNudgeCard.swift"
    "NutriSync/Views/Nudges/Components/FullScreenNudgeCard.swift"
    "NutriSync/Views/Nudges/Components/SpotlightOverlay.swift"
    "NutriSync/Views/Nudges/Components/InlineNudgeCard.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Cleaning $file..."
        # Remove simple print statements but keep error ones for now
        sed -i '' '/print("Dismissed")/d' "$file"
        sed -i '' '/print("Action tapped")/d' "$file"
        sed -i '' '/print("View stats")/d' "$file"
        sed -i '' '/print("Log meal")/d' "$file"
        sed -i '' '/print("Snooze")/d' "$file"
        sed -i '' '/print("Remind later")/d' "$file"
        sed -i '' '/print("View progress")/d' "$file"
        sed -i '' '/print("Adjust")/d' "$file"
        sed -i '' '/print("Learn")/d' "$file"
        sed -i '' '/print("View tapped")/d' "$file"
        sed -i '' '/print("Primary action")/d' "$file"
        sed -i '' '/print("Secondary action")/d' "$file"
        sed -i '' '/print("Button tapped")/d' "$file"
        sed -i '' '/print("Spotlight dismissed")/d' "$file"
        sed -i '' '/print("Learn more")/d' "$file"
        sed -i '' '/print("Try voice")/d' "$file"
        sed -i '' '/print("Check-in tapped")/d' "$file"
        sed -i '' '/print("Nudge dismissed")/d' "$file"
        sed -i '' '/print("User ate")/d' "$file"
        sed -i '' '/print("User skipped")/d' "$file"
        sed -i '' '/print(ate ? "User ate" : "User skipped")/d' "$file"
    fi
done

echo "Cleanup complete!"