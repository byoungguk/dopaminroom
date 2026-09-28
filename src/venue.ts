// ⚠️ 일부 값은 고객 확인 필요(TODO 표시). 내용·사진 출처: karaoke-tracks.com
export const VENUE = {
  name: '도파민',
  category: '강남 가라오케',
  tagline: '삼성동 프라이빗 룸 · 투명한 정찰제',
  intro:
    '강남 최고급 프라이빗 라운지 도파민입니다. 5성급 인테리어와 완벽한 방음, 100% 시크릿 동선으로 비즈니스와 파티를 완성합니다. 소규모 룸부터 VVIP 파티룸까지 24시간 운영합니다.',
  phone: '010-6466-1839',
  kakao: '', // TODO: 카카오톡 채널/오픈채팅 링크 (빈 값이면 카톡 버튼 숨김)
  manager: '담당자',
  smsTemplate: '[도파민 예약문의] 날짜/시간, 인원 남겨주시면 회신드립니다.',
  address: '서울특별시 강남구 삼성동 선릉로92길 38 제이빌딩',
  mapQuery: '서울 강남구 선릉로92길 38',
  access: ['선릉역 도보 3분', '삼성역 도보 10분', 'VIP 픽업 · 발렛 문의'],
  hours: '24시간',
  hoursNote: '연중무휴 · 예약 우선',
  staffCount: '150명+',
  staffAge: '20대 ~ 30대',
  scale: '10층 · 룸 66개',
};

// 3가지 약속
export const STRENGTHS = [
  { title: 'VVIP 전담 의전', desc: '입장부터 퇴장까지 전담 매니저가 밀착 응대합니다.' },
  { title: '365일 위생 관리', desc: '이용 후 룸 전체를 즉시 소독·정리합니다.' },
  { title: '투명한 정찰제', desc: '추가 비용 없는 정찰제. 방문 전 예상 금액을 먼저 안내합니다.' },
];

// 룸 타입
export const ROOMS = [
  { name: 'Secret Lounge', capacity: '1 ~ 4인', desc: '소규모 모임과 조용한 비즈니스 자리에 맞는 프라이빗 룸' },
  { name: 'Business Suite', capacity: '5 ~ 9인', desc: '접대와 회식에 적합한 중형 룸' },
  { name: 'VVIP Grand Hall', capacity: '10인 이상', desc: '단체 파티와 행사를 위한 대형 룸' },
];

// 시설
export const AMENITIES = [
  '전문 시공 방음 설비',
  '프리미엄 음향 · 노래 시스템',
  '음악에 맞춰 연동되는 스마트 조명',
  '프라이빗 동선 · 독립 출입',
  '24시간 운영',
  '발렛 · 픽업 문의',
];

// 이용 절차
export const STEPS = [
  { title: '전화 · 문자 문의', desc: '날짜와 시간, 인원을 알려주세요.' },
  { title: '룸 · 구성 추천', desc: '인원과 예산에 맞는 룸과 구성을 안내드립니다.' },
  { title: '비용 확인', desc: '방문 전 예상 금액을 미리 확정합니다.' },
  { title: '방문 · 착석', desc: '도착하시면 전담 매니저가 안내해 드립니다.' },
];

// 주대 (정찰제) — blog20260819 프로젝트와 동일 금액
export const TIERS = [
  { id: 'standard', name: '스텐다드', price: 150000, note: 'PHANTOM / 과일 + 맥주 + 음료 무제한' },
  { id: 'premium', name: '프리미엄', price: 190000, note: 'WICE or GOLDEN BLUE / 과일 + 맥주 + 음료 무제한' },
  { id: 'vip', name: 'VIP', price: 220000, note: 'WINDSOR17 or GOLDEN BLUE17 / 과일 + 맥주 + 음료 무제한' },
  { id: 'vvip', name: 'VVIP', price: 450000, note: 'MOET ROSE or CHANDON or BALLANTINE17 / 과일 + 맥주 + 음료 무제한' },
];

// 서비스 요금
export const FEES = {
  tcPerHour: 120000, // 인원당 1시간
  rt: 0, // TODO: 웨이터 RT (입장당) — 0이면 "문의" 표기, 계산 제외
};

export const PRICE_NOTE =
  '표기 금액은 부가세 별도이며, 요일·시간대에 따라 달라질 수 있습니다. 정확한 금액은 문의해 주세요.';

// 갤러리 (public/images/)
export const PHOTOS = [
  { src: 'images/dopamin-entrance.png', alt: '도파민 네온 사인 입구' },
  { src: 'images/venue-48.webp', alt: '샹들리에가 있는 프라이빗 룸' },
  { src: 'images/venue-51.webp', alt: '대형 소파가 놓인 룸 내부' },
  { src: 'images/venue-53.webp', alt: '샴페인과 위스키 세팅' },
  { src: 'images/venue-54.webp', alt: '룸 인테리어' },
  { src: 'images/venue-55.webp', alt: '라운지 공간' },
  { src: 'images/venue-56.webp', alt: '룸 조명' },
  { src: 'images/venue-58.webp', alt: '테이블 세팅' },
];

// 이벤트 / 특별 서비스
export const EVENTS = [
  { title: '단체 예약 상담', desc: '10인 이상 단체는 별도 상담으로 구성해 드립니다.' },
  { title: '사전 예약 안내', desc: '예약 시 룸과 구성을 미리 확정해 드립니다.' },
];

// 자주 묻는 질문
export const FAQ = [
  { q: '영업시간이 어떻게 되나요?', a: '24시간 연중무휴로 운영합니다. 예약 후 방문을 권해 드립니다.' },
  { q: '예약 없이 방문해도 되나요?', a: '가능하지만 룸 상황에 따라 대기가 있을 수 있어 예약을 권해 드립니다.' },
  { q: '비용은 어떻게 되나요?', a: '주대 등급과 인원, 이용 시간에 따라 달라집니다. 비용계산기에서 예상 금액을 확인하거나 문의해 주세요.' },
  { q: '몇 명까지 이용할 수 있나요?', a: '1인부터 10인 이상 단체까지 룸 타입에 맞춰 안내해 드립니다.' },
  { q: '주차가 되나요?', a: '발렛 및 픽업 관련은 전화로 문의해 주세요.' },
  { q: '처음 방문인데 어떻게 하나요?', a: '전화 주시면 인원과 예산에 맞춰 처음부터 안내해 드립니다.' },
];
