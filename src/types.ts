export type Series = 'essential' | 'destination-b1' | 'destination-b2';

export type WordCategory = 'topic' | 'phrasal' | 'formation';

export interface Word {
  id: string;
  series: Series;
  book: number;
  unit: number;
  category?: WordCategory;
  en: string;
  ka: string;
}

export interface BookMeta {
  book: number;
  title: string;
}
