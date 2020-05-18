module Display
  def clear_screen
    system('clear') || system('cls')
  end

  def blank_line
    puts ''
  end

  def sleep_one
    sleep(1)
  end

  def sleep_two
    sleep(2)
  end
end

class Player
  include Display
  attr_accessor :hand, :wins

  def initialize
    @hand = []
    @wins = 0
  end

  def receive_a_card(card)
    hand << card
  end

  def display_hand
    display_cards
    display_hand_value
  end

  def hand_value
    if hand.flatten.include?(11)
      value_with_aces
    else
      hand.to_h.values.reduce(:+)
    end
  end

  def display_hand_value
    puts "= #{hand_value}"
  end

  def busted?
    hand_value > 21
  end

  private

  def value_with_aces
    count = hand.to_h.values.reduce(:+)
    return count if count <= 21
    aces_count = hand.flatten.count(11)
    loop do
      count -= 10
      aces_count -= 1
      break if count <= 21 || aces_count == 0
    end
    count
  end
end

class Dealer < Player
  def display_first_card
    puts "Dealer's first card is #{hand[0][0]}"
    blank_line
  end

  def display_first_card_again
    puts "(Dealer's first card is #{hand[0][0]})"
    blank_line
  end

  def display_cards
    sleep_one
    puts "Dealer has the following cards:"
    blank_line
    hand.to_h.keys.each { |card| puts card }
  end

  def declares_stay
    blank_line
    sleep_one
    puts "Dealer must stay with #{hand_value}"
  end

  def declares_hit
    blank_line
    sleep_one
    puts "Dealer hits"
  end

  def must_stay?
    hand_value.between?(17, 21)
  end
end

class Human < Player
  attr_writer :stays

  def stays?
    @stays
  end

  def display_cards
    puts "You have the following cards:"
    sleep_one
    blank_line
    hand.to_h.keys.each { |card| puts card }
  end
end

class TwentyOne
  include Display
  attr_accessor :dealer, :human, :deck, :current_player, :next_card

  CARD_SUITS = ['Hearts', 'Diamonds', 'Spades', 'Clubs']
  CARD_FACES = (2..10).to_a + ['Jack', 'Queen', 'King', 'Ace']

  def initialize
    clear_screen
    @dealer = Dealer.new
    @human = Human.new
    @current_player = human
    shuffle_deck
  end

  def play_game
    display_welcome_message
    loop do
      deal_first_two_cards
      display_first_cards
      human_plays
      dealer_plays unless human.busted?
      update_game_score
      display_outcome
      break unless play_again?
      reset_game
      declare_new_round
    end
    display_goodbye_message
  end

  private

  def shuffle_deck
    self.deck = []
    CARD_SUITS.each do |suit|
      CARD_FACES.each do |face|
        value = case face
                when 2..10
                  face
                when 'Ace'
                  11
                else
                  10
                end
        deck << ["#{face} of #{suit}", value]
      end
    end
    deck.shuffle!
  end

  def deal_first_two_cards
    2.times do
      deal_next_card
      toggle_current_player
      deal_next_card
      toggle_current_player
    end
  end

  def toggle_current_player
    self.current_player = current_player == human ? dealer : human
  end

  def deal_next_card
    self.next_card = deck.pop
    current_player.receive_a_card(next_card)
  end

  def display_welcome_message
    clear_screen
    puts "Welcome to Twenty-one"
    blank_line
    puts "The player with the highest score without surpassing twenty-one wins!"
    blank_line
    puts "press 'enter' to continue"
    gets.chomp
  end

  def display_first_cards
    clear_screen
    dealer.display_first_card
    sleep_one
    human.display_hand
  end

  def human_plays
    loop do
      prompt_human_hit_or_stay
      break display_human_stays if human.stays?
      display_human_hits
      clear_screen
      deal_next_card
      dealer.display_first_card_again
      display_next_card
      human.display_hand
      break if human.busted?
    end
  end

  def prompt_human_hit_or_stay
    answer = ''
    loop do
      blank_line
      puts "Would you like to hit or stay? (h/s)"
      answer = gets.chomp.downcase
      break if %w[s h].include?(answer)
      puts "Sorry, valid choices are 'h' for hit and 's' for stay"
    end
    human.stays = answer == 's' ? true : false
  end

  def display_human_stays
    clear_screen
    puts "You stayed with #{human.hand_value}"
    blank_line
    sleep_one
  end

  def display_human_hits
    blank_line
    puts "You hit"
    sleep_one
  end

  def display_next_card
    puts "Next card is a #{next_card[0]}"
    blank_line
    sleep_one
  end

  def dealer_plays
    toggle_current_player
    declare_dealer_turn
    loop do
      dealer.display_hand
      break if dealer.busted?
      break dealer.declares_stay if dealer.must_stay?
      dealer.declares_hit
      prompt_human_continue
      display_human_stays
      deal_next_card
      display_next_card
    end
  end

  def declare_dealer_turn
    puts "Dealer's turn"
    blank_line
    sleep_one
  end

  def prompt_human_continue
    blank_line
    puts "press 'enter' to continue"
    gets.chomp
    clear_screen
  end

  def display_outcome
    sleep_two
    blank_line
    if human.busted?
      display_human_busted
    elsif dealer.busted?
      display_dealer_busted
    elsif a_tie?
      display_tie_outcome
    elsif human_higher_value?
      display_human_higher_value
    else
      display_dealer_higher_value
    end
    display_score
  end

  def a_tie?
    dealer.hand_value == human.hand_value
  end

  def display_tie_outcome
    puts "It's a tie. Both have #{dealer.hand_value}"
  end

  def display_human_busted
    puts "You busted. Dealer wins!"
  end

  def display_dealer_busted
    puts "Dealer busted. You win!"
  end

  def human_higher_value?
    human.hand_value > dealer.hand_value
  end

  def display_human_higher_value
    puts "You win! #{human.hand_value} beats #{dealer.hand_value}"
  end

  def display_dealer_higher_value
    puts "Dealer wins! #{dealer.hand_value} beats #{human.hand_value}"
  end

  def display_score
    blank_line
    puts "The current score is"
    puts "=>    You: #{human.wins}"
    puts "=> Dealer: #{dealer.wins}"
  end

  def play_again?
    sleep_one
    answer = ''
    loop do
      blank_line
      puts "Would you like to play another round? (y/n)"
      answer = gets.chomp.downcase
      break if %w[y n].include?(answer)
      puts "Sorry, that is not a valid answer. Please answer 'y' or 'n'"
    end
    answer == 'y'
  end

  def update_game_score
    return if a_tie?
    if dealer.busted? || human_higher_value?
      human.wins += 1
    else
      dealer.wins += 1
    end
  end

  def reset_game
    human.hand = []
    dealer.hand = []
    self.current_player = human
    shuffle_deck
  end

  def declare_new_round
    clear_screen
    puts "New Round!"
    blank_line
    sleep_one
    puts "Dealer shuffles and deals new cards..."
    sleep_two
  end

  def display_goodbye_message
    puts "Thank you for playing Twenty-One! Goodbye"
  end
end

TwentyOne.new.play_game
