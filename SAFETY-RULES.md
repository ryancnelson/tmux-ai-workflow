# ⚠️ CRITICAL AI SAFETY RULES - READ FIRST ⚠️

## 🚨 ABSOLUTE PROHIBITIONS 🚨

### 1. NEVER USE HEREDOC SYNTAX
```bash
# ❌ NEVER DO THIS - WILL BREAK SESSIONS
cat << EOF > file.txt
content here
EOF

# ✅ ALWAYS USE BASE64 INSTEAD
echo "Y29udGVudCBoZXJlCg==" | base64 -d > file.txt
```

**Why heredocs break:** 
- Shell escaping issues with quotes/special chars
- EOF markers get confused with other text  
- Sessions get stuck in `>` prompt state
- **Example of the problem:** `echo "EOF"; echo "next command"` makes a line that doesn't end with just "EOF"

### 2. NEVER RUN RECOVERY COMMANDS IN STUCK PANES
```bash
# ❌ WRONG - Running recovery in the stuck pane itself
# (from inside ryan-workflow pane that's stuck)
./tmux-recover left emergency  

# ✅ CORRECT - Run from outside or different pane
# (from outside tmux entirely, or different pane)
tmux send-keys -t ryan-workflow:0.0 C-c
./tmux-recover left emergency
```

**Why this matters:**
- Stuck pane can't execute new commands
- Creates recursive stuck state
- Must use external control

## 🛡️ MANDATORY BASE64 PROTOCOL

For ANY file content, follow this pattern:

1. **Encode your content:**
   ```bash
   echo "your content here" | base64
   ```

2. **Inject via base64:**
   ```bash
   echo "WW91ciBjb250ZW50IGhlcmUK" | base64 -d > filename.txt
   # or append:
   echo "WW91ciBjb250ZW50IGhlcmUK" | base64 -d >> filename.txt
   ```

3. **For multi-line content:**
   ```bash
   # Create the base64 content first
   content="line 1
   line 2  
   line 3"
   echo "$content" | base64 | tr -d '\n'
   # Then use the single-line base64 result
   ```

## 🚑 RECOVERY PROTOCOL

When a pane gets stuck:

1. **Identify the stuck pane** (left=0.0, top=0.1, bottom=0.2)
2. **From outside tmux or different pane:**
   ```bash
   tmux send-keys -t ryan-workflow:0.X C-c
   tmux send-keys -t ryan-workflow:0.X "clear" Enter
   ```
3. **Or use the recovery script:**
   ```bash
   ./tmux-recover [pane] emergency
   ```

## 📋 DETECTION PATTERNS

**Signs a pane is stuck:**
- Prompt shows `>` instead of `ryan-workflow-bash:pane $`
- Commands don't execute
- Screen frozen or unresponsive
- Heredoc syntax was used recently

**Emergency detection command:**
```bash
tmux capture-pane -t ryan-workflow:0.0 -p | tail -1
```

## 🔒 WHY THESE RULES EXIST

1. **Heredocs break shell parsing** - quotes, backticks, variables all cause issues
2. **Base64 is bulletproof** - handles any character safely
3. **Stuck panes compound** - trying to fix from inside makes it worse  
4. **LLMs forget these rules** - that's why they're prominently placed

## ✅ COMPLIANCE CHECK

Before any file operation, ask:
- [ ] Am I using base64 encoding?
- [ ] Am I avoiding heredoc syntax?
- [ ] If pane is stuck, am I running recovery from outside?
- [ ] Did I test my base64 encoding first?

**Remember: These rules prevent 90% of session problems. Follow them religiously.**
