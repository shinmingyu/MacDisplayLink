## 🧩 커밋 메시지 규칙 요약

| 구분    | 규칙                                                                  |
| ----- | ------------------------------------------------------------------- |
| 제목    | `<Type>. 요약 설명` or `📝 <Type>. 요약 설명`<br>Type은 대문자로 시작. 마침표 뒤 공백 필수 |
| 요약 길이 | 한글 기준 30자 이내 권장                                             |
| 본문    | `Why:` 변경 이유 / `How:` 변경 방법                                         |

## ✅ 커밋 메시지 예시

```text
📝 Docs. 컴포넌트 구조 개선

Why:
- View 네이밍 통일

How:
- CycleView → CycleProgressView로 변경
```

```text
Fix. 로그인 실패 시 예외처리 추가

Why:
- 빈 토큰에서 앱이 크래시 발생

How:
- if 조건문 보호 및 로그 출력 추가
```



## ✅ 커밋 메시지 예시

```text
📝 Docs. 컴포넌트 구조 개선

Why:
- View 네이밍 통일

How:
- CycleView → CycleProgressView로 변경
```

```text
Fix. 로그인 실패 시 예외처리 추가

Why:
- 빈 토큰에서 앱이 크래시 발생

How:
- if 조건문 보호 및 로그 출력 추가
```

## ❌ 잘못된 메시지 예시

```text
readme 업데이트
```

```text
fix: 로그인 고침
```

```text
📝 Docs. 프로젝트 가이드 문서 추가

Why:
- 팀 협업을 위한 규칙 문서화 필요

How:
- docs 폴더 생성

🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>
```
> ⚠️ 커밋 메시지에 AI 생성 도구 서명이나 Co-Authored-By 같은 불필요한 메타데이터를 포함하지 마세요.