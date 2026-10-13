// data.jsx — fake data for the prototype

const FAKE_LIBRARY = [
  {
    id: 'current',
    title: '제품팀 주간 스탠드업 — 5월 첫째 주',
    file: '2026-05-04 제품팀 스탠드업.m4a',
    date: '2026년 5월 4일',
    duration: '32:18',
    speakers: 4,
    template: 'decision-action',
    pinned: true,
    decisions: 3,
    actions: 7,
    status: 'done',
  },
  {
    id: 'm-2',
    title: '디자인 시스템 v2 킥오프',
    file: '2026-05-02 ds-v2-kickoff.m4a',
    date: '2026년 5월 2일',
    duration: '54:02',
    speakers: 6,
    template: 'default',
    decisions: 5,
    actions: 12,
    status: 'done',
  },
  {
    id: 'm-3',
    title: '이지윤 고객사 인터뷰 (스타트업 PM)',
    file: '2026-04-28 customer-jiyun.m4a',
    date: '2026년 4월 28일',
    duration: '47:31',
    speakers: 2,
    template: 'customer-interview',
    decisions: 0,
    actions: 4,
    status: 'done',
  },
  {
    id: 'm-4',
    title: '엔지니어링 1:1 — 박민호',
    file: '2026-04-27 1on1-minho.m4a',
    date: '2026년 4월 27일',
    duration: '28:09',
    speakers: 2,
    template: 'default',
    decisions: 1,
    actions: 3,
    status: 'done',
  },
  {
    id: 'm-5',
    title: 'Q2 OKR 검토 미팅',
    file: '2026-04-25 q2-okr-review.m4a',
    date: '2026년 4월 25일',
    duration: '1:12:48',
    speakers: 8,
    template: 'decision-action',
    decisions: 8,
    actions: 14,
    status: 'done',
  },
  {
    id: 'm-6',
    title: '온보딩 플로우 사용성 인터뷰',
    file: '2026-04-22 ux-research-3.m4a',
    date: '2026년 4월 22일',
    duration: '38:55',
    speakers: 2,
    template: 'customer-interview',
    decisions: 0,
    actions: 6,
    status: 'done',
  },
];

const SPEAKER_PALETTE = [
  { name: '김서연', short: '김', color: '#FF6A3D' },
  { name: '박민호', short: '박', color: '#7A5AE0' },
  { name: '이지윤', short: '이', color: '#0E7C86' },
  { name: '정하늘', short: '정', color: '#E0245E' },
];

const SPEAKER_COLORS = [
  '#FF6A3D', '#E0245E', '#7A5AE0', '#0E7C86',
  '#1F8A5B', '#C28A1A', '#2A6FDB', '#9C2BAD',
];

const FAKE_TRANSCRIPT = [
  { id: 1, t: '00:00', tSec: 0, speaker: 0, text: '자, 다들 모이셨죠? 5월 첫째 주 스탠드업 시작할게요. 오늘 어젠다는 세 가지예요. 베타 출시 일정 점검, 가격 정책 결정, 그리고 신규 채용 관련 논의. 이지윤님부터 지난주 진행 상황 공유 부탁드릴게요.' },
  { id: 2, t: '00:14', tSec: 14, speaker: 2, text: '네, 베타 출시는 원래 5월 12일 목표였는데, QA에서 결제 모듈에 이슈가 두 개 발견됐어요. 하나는 환불 케이스에서 상태가 꼬이는 거고, 다른 하나는 영수증 PDF가 한글에서 깨지는 문제예요.' },
  { id: 3, t: '00:32', tSec: 32, speaker: 0, text: '둘 다 블로커인가요?' },
  { id: 4, t: '00:34', tSec: 34, speaker: 2, text: '환불 쪽은 명백히 블로커고요, PDF는… 우회 방법이 있어서 일단 출시 후에 패치해도 될 것 같아요.' },
  { id: 5, t: '00:42', tSec: 42, speaker: 1, text: '환불 이슈는 제가 봤는데 상태 머신 쪽이라 fix 자체는 반나절이면 될 것 같아요. 다만 회귀 테스트가 좀 길어요.' },
  { id: 6, t: '00:54', tSec: 54, speaker: 0, text: '그러면 5월 14일로 이틀 미루는 게 안전하겠네요. 다들 동의하시면 일정 14일로 확정하고 가시죠.' },
  { id: 7, t: '01:08', tSec: 68, speaker: 3, text: '동의합니다. 마케팅 측 발표 자료도 그날 기준으로 다시 잡을게요.' },
  { id: 8, t: '01:14', tSec: 74, speaker: 0, text: '좋아요. 그러면 다음, 가격 정책. 정하늘님 진행해주세요.' },
  { id: 9, t: '01:19', tSec: 79, speaker: 3, text: '지난주에 두 가지 옵션 비교했었죠. A안은 월 9,900원 단일 플랜, B안은 무료 + Pro 19,000원 투트랙. 컨버전 시뮬레이션 돌려봤는데, 6개월 누적 매출 기준 B안이 약 30% 높게 나왔어요.' },
  { id: 10, t: '01:42', tSec: 102, speaker: 1, text: '저는 B안에 한 표인데, Pro 가격이 19,000원이면 좀 비싸 보이지 않을까요? 14,900원 정도가 더 자연스러울 것 같은데요.' },
  { id: 11, t: '01:55', tSec: 115, speaker: 3, text: '그것도 같이 시뮬해봤어요. 14,900원으로 내리면 컨버전은 1.4배 올라가는데 ARPU가 떨어져서 결국 매출은 비슷해요. 19,000원 유지가 나아 보여요.' },
  { id: 12, t: '02:12', tSec: 132, speaker: 0, text: '그러면 B안 + Pro 19,000원으로 결정할까요? … 네, 그렇게 가시죠. 박민호님이 결제 페이지 카피 수정 작업 맡아주시고, 이지윤님은 가격 정책 노션 페이지 업데이트 부탁드려요.' },
  { id: 13, t: '02:32', tSec: 152, speaker: 1, text: '넵.' },
  { id: 14, t: '02:33', tSec: 153, speaker: 2, text: '오케이, 이번 주 안에 정리할게요.' },
];

const FAKE_MINUTES = `# 제품팀 주간 스탠드업 — 5월 첫째 주

**일시** 2026년 5월 4일 (월) 10:00–10:32
**참석** 김서연, 박민호, 이지윤, 정하늘
**서기** record-up (자동 생성)
**원본** 2026-05-04 제품팀 스탠드업.m4a

---

## 한눈에 보기
- 베타 출시 일정 **5월 12일 → 5월 14일**로 조정 (결제 모듈 환불 이슈 수정)
- 가격 정책 **B안 (무료 + Pro 19,000원)** 채택
- 마케팅·노션·결제 카피 작업 분담 완료

## 결정 사항
1. **베타 출시일을 5월 14일로 확정한다.** 환불 상태 머신 이슈가 블로커이며, 회귀 테스트 시간을 확보해야 함. PDF 한글 깨짐은 우회 가능하므로 출시 후 패치.
2. **가격 정책은 B안(무료 + Pro 19,000원)으로 간다.** 14,900원으로 낮추면 컨버전은 오르지만 ARPU 감소로 매출이 비슷하게 수렴함.
3. **마케팅 발표 자료를 14일 기준으로 재조정한다.**

## 액션 아이템
- [ ] **박민호** — 환불 상태 머신 fix + 회귀 테스트 (~5/8)
- [ ] **이지윤** — 가격 정책 노션 페이지 업데이트 (~5/9)
- [ ] **박민호** — 결제 페이지 카피를 B안 기준으로 수정 (~5/10)
- [ ] **정하늘** — 마케팅 발표 자료 14일 기준 재구성 (~5/12)
- [ ] **김서연** — QA 결과 공유 후 출시 GO/NO-GO 콜 (5/13)

## 논의 요약

### 베타 출시 일정
QA에서 결제 모듈 이슈 두 건 발견. (1) 환불 케이스에서 상태가 꼬이는 문제 — fix 자체는 반나절이지만 회귀 테스트 필요. (2) 영수증 PDF 한글 깨짐 — 우회 가능. 안전하게 5월 14일로 이틀 연기.

### 가격 정책
- A안: 월 9,900원 단일 플랜
- B안: 무료 + Pro 19,000원 투트랙
6개월 누적 매출 기준 B안이 약 30% 높음. Pro 가격을 14,900원으로 낮춰도 ARPU 감소로 총매출은 거의 동일.

### 신규 채용
시간 관계상 다음 미팅으로 이월.
`;

window.FAKE_LIBRARY = FAKE_LIBRARY;
window.SPEAKER_PALETTE = SPEAKER_PALETTE;
window.SPEAKER_COLORS = SPEAKER_COLORS;
window.FAKE_TRANSCRIPT = FAKE_TRANSCRIPT;
window.FAKE_MINUTES = FAKE_MINUTES;
