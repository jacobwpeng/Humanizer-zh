# Humanizer-zh（gh skill 镜像）

[op7418/Humanizer-zh](https://github.com/op7418/Humanizer-zh) 的自动同步镜像，把根目录的 `SKILL.md` 放到 `skills/humanizer-zh/`，以便 `gh skill` 远程发现（见 [cli/cli#13552](https://github.com/cli/cli/issues/13552)）。

```bash
gh skill install jacobwpeng/Humanizer-zh humanizer-zh --agent cursor --scope user
gh skill update --all
```

- 内容以上游为准：`.github/workflows/sync-upstream.yml` 每天用上游最新内容重新生成 `skills/`，除 `.github/` 外不要手动修改。
- 手动同步：`gh workflow run sync-upstream.yml -R jacobwpeng/Humanizer-zh`
