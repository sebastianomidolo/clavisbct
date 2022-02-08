module CodiceFiscale
  module Codes
    include Configurable
    extend self

    ITALY = 'Italia'

    MONTH_CODES = %w[A B C D E H L M P R S T]

    ODD_CODES = {'0' => 1, '1' => 0, '2' => 5, '3' => 7, '4' => 9, '5' => 13, '6' => 15, '7' => 17, '8' => 19, '9' => 21, 'A' => 1, 'B' => 0,
                 'C' => 5, 'D' => 7, 'E' => 9, 'F' => 13, 'G' => 15, 'H' => 17, 'I' => 19, 'J' => 21, 'K' => 2, 'L' => 4, 'M' => 18, 'N' => 20,
                 'O' => 11, 'P' => 3, 'Q' => 6, 'R' => 8, 'S' => 12, 'T' => 14, 'U' => 16, 'V' => 10, 'W' => 22, 'X' => 25, 'Y' => 24, 'Z' => 23}

    EVEN_CODES = {'0' => 0, '1' => 1, '2' => 2, '3' => 3, '4' => 4, '5' => 5, '6' => 6, '7' => 7, '8' => 8, '9' => 9, 'A' => 0, 'B' => 1,
                  'C' => 2, 'D' => 3, 'E' => 4, 'F' => 5, 'G' => 6, 'H' => 7, 'I' => 8, 'J' => 9, 'K' => 10, 'L' => 11, 'M' => 12, 'N' => 13,
                  'O' => 14, 'P' => 15, 'Q' => 16, 'R' => 17, 'S' => 18, 'T' => 19, 'U' => 20, 'V' => 21, 'W' => 22, 'X' => 23, 'Y' => 24, 'Z' => 25}

    GENDERS = [:male, :female]

    def month_letter month_number
      month_number <= 0 ? nil : MONTH_CODES[month_number-1]
    end

    def city city_name, province_code
      return config.city_code.call(city_name, province_code) if config.city_code
      CSV.foreach config.city_codes_csv_path do |row|
        if city_name.casecmp(row[0]).zero? and province_code.casecmp(row[1]).zero?
          return row[2].upcase
        end
      end
      nil
    end

    def country country_name
      return config.country_code.call(country_name) if config.country_code
      CSV.foreach config.country_codes_csv_path do |row|
        return row[2].upcase if country_name.casecmp(row[0]).zero? or country_name.casecmp(row[1]).zero?
      end
      nil
    end

    def odd_character character
      ODD_CODES[character.upcase]
    end

    def even_character character
      EVEN_CODES[character.upcase]
    end

    def control_character number
      Alphabet.letters[number]
    end

    def italy? country_name
      ITALY.casecmp(country_name.strip).zero?
    end
  end
end