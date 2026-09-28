// ⚠️ 고객 확인 필요: 값은 임시(placeholder). 실제 정보로 교체하세요.
export const VENUE = {
  name: '도파민',
  category: '강남 하이퍼블릭',
  tagline: '선릉역 3분 · 강남 최대 규모 하이퍼블릭',
  phone: '010-6466-1839',
  kakao: '', // TODO: 카카오톡 채널/오픈채팅 링크 (빈 값이면 카톡 버튼 숨김)
  manager: '담당자', // TODO
  smsTemplate: '[도파민 예약문의] 날짜/시간, 인원 남겨주시면 회신드립니다.',
  address: '서울특별시 강남구 선릉로92길 38', // TODO 확인
  mapQuery: '서울 강남구 선릉로92길 38',
  access: ['선릉역 (2호선·수인분당선) 도보 3분', '삼성역 (2호선·9호선) 도보 10분', '발렛파킹 문의'],
  hours: '21:00 ~ 04:00',
  hoursNote: '연중무휴 · 예약 우선',
  staffCount: '150명+',
  staffAge: '20대 ~ 30대',
  scale: '10층 · 룸 66개',
};

// 강점 3가지
export const STRENGTHS = [
  { title: '강남 최대 규모', desc: `${VENUE.scale} 규모, 상시 대기 인원 ${VENUE.staffCount}` },
  { title: '투명한 가격', desc: '추가 비용 없는 정찰제. 방문 전 예상 금액을 먼저 안내합니다.' },
  { title: '선릉역 3분', desc: '역에서 도보 3분, 건물 앞 하차 가능' },
];

// 이용 절차
export const STEPS = [
  { title: '전화 · 문자 문의', desc: '날짜와 시간, 인원을 알려주세요.' },
  { title: '자리 · 구성 추천', desc: '인원과 예산에 맞는 룸과 구성을 안내드립니다.' },
  { title: '비용 확인', desc: '방문 전 예상 금액을 미리 확정합니다.' },
  { title: '방문 · 착석', desc: '도착하시면 바로 안내해 드립니다.' },
];

// 주대 등급 (가격 0 = "문의" 표시, 계산기에서 제외)
export const TIERS = [
  { id: 'standard', name: '스탠다드', price: 0 },
  { id: 'premium', name: '프리미엄', price: 0 },
  { id: 'vip', name: 'VIP', price: 0 },
  { id: 'vvip', name: 'VVIP', price: 0 },
];

// 서비스 요금
export const FEES = {
  tcPerHour: 0, // 인원당 시간당 TC
  rt: 0, // 웨이터 RT (입장당)
  serviceRate: 0, // 0.1 = 봉사료 10%
  vatRate: 0.1,
  vatIncluded: false, // TODO: 표기 금액 부가세 포함 여부
};

// 안주 (선택 시 계산기에 합산)
export const SIDES = [
  { id: 'none', name: '선택 안 함', price: 0 },
  { id: 'basic', name: '기본 안주', price: 0 },
  { id: 'fruit', name: '과일', price: 0 },
];

export const PRICE_NOTE =
  '표기 금액은 부가세 별도이며, 요일·시간대에 따라 달라질 수 있습니다. 정확한 금액은 문의해 주세요.';

// 이벤트 / 특별 서비스
export const EVENTS = [
  { title: '단체 예약 상담', desc: '10인 이상 단체는 별도 상담으로 구성해 드립니다.' },
  { title: '사전 예약 안내', desc: '예약 시 자리와 구성을 미리 확정해 드립니다.' },
];

// 자주 묻는 질문
export const FAQ = [
  { q: '영업시간이 어떻게 되나요?', a: `${VENUE.hours}까지 영업합니다. ${VENUE.hoursNote}.` },
  { q: '예약 없이 방문해도 되나요?', a: '가능하지만 자리 상황에 따라 대기가 있을 수 있어 예약을 권해 드립니다.' },
  { q: '비용은 어떻게 되나요?', a: '주대 등급과 인원, 이용 시간에 따라 달라집니다. 비용계산기에서 예상 금액을 확인하거나 문의해 주세요.' },
  { q: '주차가 되나요?', a: '발렛파킹 관련은 전화로 문의해 주세요.' },
  { q: '처음 방문인데 어떻게 하나요?', a: '전화 주시면 인원과 예산에 맞춰 처음부터 안내해 드립니다.' },
  { q: '단체도 가능한가요?', a: '단체 예약 가능합니다. 인원을 알려주시면 룸을 준비해 드립니다.' },
];
