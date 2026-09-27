// ⚠️ 고객 확인 필요: 아래 값은 전부 임시(placeholder)입니다. 실제 정보로 교체하세요.
export const VENUE = {
  name: '도파민',
  category: '강남 하이퍼블릭',
  tagline: '선릉역 3분 거리, 강남 최대 규모 하이퍼블릭',
  phone: '010-0000-0000', // TODO
  kakao: 'https://open.kakao.com/', // TODO
  address: '서울특별시 강남구 선릉로92길 38', // TODO 확인
  addressDetail: '선릉역 도보 3분',
  mapQuery: '서울 강남구 선릉로92길 38',
  hours: '21:00 ~ 04:00',
  info: [
    { label: '규모', value: '10층 · 룸 66개' },
    { label: '영업시간', value: '21:00 ~ 04:00' },
    { label: '주차', value: '발렛 가능' },
    { label: '위치', value: '선릉역 3번 출구 도보 3분' },
    { label: '예약', value: '전화 · 카카오톡 상시 접수' },
    { label: '이용안내', value: '만 19세 이상 성인 전용' },
  ],
  // 가격: 반드시 실제 금액으로 교체 (표기 금액은 부가세 별도 여부까지 명확히)
  prices: [
    { item: 'TC (1시간)', price: 0, note: '인원당' },
    { item: '주대 (기본)', price: 0, note: '' },
    { item: '룸 이용료', price: 0, note: '' },
  ],
  priceNote: '모든 금액은 부가세 별도이며, 요일·시간대에 따라 달라질 수 있습니다. 정확한 금액은 문의 바랍니다.',
  facilities: ['프라이빗 룸', '발렛파킹', '단체 예약', '사전 예약 할인'],
};

// 가격 계산기 기본값 (고객 확인 후 실제 단가로 교체)
export const CALC = {
  tcPerHour: 0,
  bottlePrice: 0,
  roomFee: 0,
  serviceRate: 0, // 예: 0.1 = 10%
  vatRate: 0.1,
};
