# Voice Input UI Implementation Plan

## User-Approved Design Decisions

### Selected Approaches:
1. **Black Screen Fix**: Pre-initialize camera session on app launch (Option B)
2. **Manual Text Input**: Long-press on transcribed text to enable editing mode (Option C)
3. **Description Box**: Adaptive sizing based on screen height (Option A)
4. **Button Styling**: Use SharedComponents.PrimaryButton BUT preserve current voiceInputButton design (Hybrid)
5. **Skip Button**: Below "Done/Analyze" button as secondary action (Option B)
6. **Priority Order**: UI fixes first → Manual text input → Camera initialization

## Implementation Steps (Execute in Order)

### PHASE A: UI Layout Fixes (Priority 1)

#### Step 1: Fix Description Box Adaptive Sizing
**File**: `NutriSync/Views/Scan/Camera/RealVoiceInputView.swift`

**Changes**:
- Replace fixed `maxHeight: 220` with dynamic calculation
- Calculate available height: `UIScreen.main.bounds.height - safeAreaInsets - otherElements`
- Implement responsive instruction display based on device size
- Test on iPhone SE, iPhone 15, iPhone 15 Pro Max

**Code Location**: Lines 62-67, 279-324

**Implementation**:
```swift
// Add computed property for adaptive height
private var instructionMaxHeight: CGFloat {
    let screenHeight = UIScreen.main.bounds.height
    let minHeight: CGFloat = 150
    let maxHeight: CGFloat = 300
    
    // Adjust based on device size
    if screenHeight < 700 { // SE, mini
        return minHeight
    } else if screenHeight < 850 { // Standard
        return 220
    } else { // Pro Max
        return maxHeight
    }
}
```

#### Step 2: Update Navigation Button Styling
**File**: `NutriSync/Views/Scan/Camera/RealVoiceInputView.swift`

**Changes**:
- Import SharedComponents
- Keep current voiceInputButton visual design (30pt radius, custom styling)
- Update color from hardcoded `Color.green` to `Color.nutriSyncAccent`
- Add haptic feedback using `UIImpactFeedbackGenerator`

**Code Location**: Lines 253-275

**Implementation**:
```swift
// Keep current button design but update colors
Button(action: {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
    // existing action
}) {
    // existing design
    .background(
        RoundedRectangle(cornerRadius: 30) // Keep 30pt
            .fill(Color.nutriSyncAccent) // Use theme color
    )
}
```

#### Step 3: Add Skip Button
**File**: `NutriSync/Views/Scan/Camera/RealVoiceInputView.swift`

**Changes**:
- Add skip button below the Done/Analyze button
- Use established skip button pattern from `CheckInButton.swift`
- Pass nil/empty result to completion handler

**Code Location**: After line 275

**Implementation**:
```swift
// Add skip button as secondary action
Button(action: {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
    dismiss()
    completion(capturedImage, "") // Empty description
}) {
    Text("Skip voice description")
        .font(.system(size: 14))
        .foregroundColor(Color.white.opacity(0.5))
        .padding(.top, 8)
}
```

### PHASE B: Manual Text Input (Priority 2)

#### Step 4: Implement Long-Press Edit Mode
**File**: `NutriSync/Views/Scan/Camera/RealVoiceInputView.swift`

**Changes**:
- Add `@State private var isEditingText = false`
- Add `@FocusState private var isTextFieldFocused: Bool`
- Convert transcription display to conditional TextField
- Add long-press gesture recognizer

**Code Location**: Lines 336-375 (transcription display area)

**Implementation**:
```swift
@State private var isEditingText = false
@State private var editableText = ""
@FocusState private var isTextFieldFocused: Bool

// In transcription display area
Group {
    if isEditingText {
        TextField("Type or edit your meal description", text: $editableText, axis: .vertical)
            .textFieldStyle(.plain)
            .focused($isTextFieldFocused)
            .onSubmit {
                transcribedText = editableText
                isEditingText = false
            }
    } else {
        Text(transcribedText.isEmpty ? "Tap microphone to start" : transcribedText)
            .onLongPressGesture(minimumDuration: 0.5) {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                editableText = transcribedText
                isEditingText = true
                isTextFieldFocused = true
            }
    }
}
```

#### Step 5: Add Visual Feedback for Edit Mode
**Changes**:
- Add border/background change when in edit mode
- Show "Done Editing" button in toolbar
- Add instruction text for long-press capability

**Implementation**:
```swift
// Visual indicator when editable
.background(
    RoundedRectangle(cornerRadius: 12)
        .stroke(isEditingText ? Color.nutriSyncAccent : Color.clear, lineWidth: 2)
)

// Add hint text when not editing
if !isEditingText && !transcribedText.isEmpty {
    Text("Long press to edit")
        .font(.caption)
        .foregroundColor(Color.white.opacity(0.4))
}
```

### PHASE C: Camera Pre-initialization (Priority 3)

#### Step 6: Pre-warm Camera Session
**File**: `NutriSync/Views/Scan/Camera/RealCameraPreviewView.swift`

**Changes**:
- Create static camera session manager
- Initialize on app launch or tab selection
- Add session state tracking

**Code Location**: Lines 20-50

**Implementation**:
```swift
// Add to RealCameraPreviewView
static let sharedCameraSession = CameraSessionManager()

class CameraSessionManager: ObservableObject {
    private var session: AVCaptureSession?
    @Published var isReady = false
    
    func preWarmSession() {
        guard session == nil else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let newSession = AVCaptureSession()
            // Configure session...
            
            DispatchQueue.main.async {
                self.session = newSession
                self.isReady = true
            }
        }
    }
}
```

#### Step 7: Initialize Camera on Tab View Load
**File**: `NutriSync/Views/Tabs/ScanTabView.swift`

**Changes**:
- Call pre-warm on view appear
- Show loading state if camera not ready
- Prevent capture until session ready

**Code Location**: Lines 50-70

**Implementation**:
```swift
.onAppear {
    RealCameraPreviewView.sharedCameraSession.preWarmSession()
}

// In capture button action
if RealCameraPreviewView.sharedCameraSession.isReady {
    // Allow capture
} else {
    // Show "Camera preparing..." message
}
```

## Testing Checklist

### UI Testing
- [ ] Description box doesn't scroll on iPhone 15 Pro
- [ ] Description box shows fewer items on iPhone SE
- [ ] Skip button appears below Analyze button
- [ ] Buttons use theme colors (nutriSyncAccent)
- [ ] Haptic feedback triggers on all button presses

### Functionality Testing
- [ ] Long-press enables text editing
- [ ] Keyboard appears when editing
- [ ] Can type and submit custom description
- [ ] Edit mode has visual indicators
- [ ] Skip button closes view with empty description

### Camera Testing
- [ ] No black screen on first capture
- [ ] Camera ready indicator shows
- [ ] Session persists between captures
- [ ] Memory usage stays reasonable
- [ ] Works after app background/foreground

## Success Criteria

1. **No Black Screen**: First photo capture works 100% of the time
2. **Responsive Layout**: Description box fits without scrolling on all devices
3. **Text Input Works**: Users can edit transcribed text via long-press
4. **Consistent Styling**: All buttons match app theme
5. **Skip Option Available**: Users can skip voice input step
6. **Performance**: Camera ready in < 2 seconds
7. **Memory**: No memory leaks from camera session

## Rollback Plan

If any step causes issues:
1. Git stash changes for that step
2. Test previous steps still work
3. Document issue in progress file
4. Move to next step if possible
5. Create hotfix branch if critical

## Compilation Test Commands

```bash
# After each step, test compilation:
swiftc -parse -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0 -import-objc-header NutriSync-Bridging-Header.h \
  NutriSync/Views/Scan/Camera/RealVoiceInputView.swift \
  NutriSync/Views/Scan/Camera/RealCameraPreviewView.swift \
  NutriSync/Views/Tabs/ScanTabView.swift

# Test in Xcode after each phase
# Capture screenshots for verification
```

## Next Session Instructions

Start Phase 3 Implementation with:
```
@plan-voice-input-ui.md @research-voice-input-ui.md
"Execute Step 1: Fix Description Box Adaptive Sizing"
```

---
*Plan created with user input and approval*
*Ready for Phase 3: Implementation*