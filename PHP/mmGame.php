<?php

define('RED', 1);
define('ORANGE', 2);
define('YELLOW', 3);
define('GREEN', 4);
define('BLUE', 5);
define('PURPLE', 6);
define('WHITE', 7);
define('BLACK', 8);

/*
    MMGame Interface

    Client code (for example a php file that generates JSON responses) uses the API
    of this interface to create and play a game.

    Because the MMGame interface is client agnostic, we could just as well have it be 
    called from a php client that generates XML, HTML, or any other format.  One could also
    have it be called from a CLI php script.
*/
interface MMGame {

    public function guess($aGuess);
    public function res();
    public function status();

}

/*
    CodeGenerator is an interface that represents a strategy for creating secret codes.
*/
interface CodeGenerator {

    public function generate();
    public function get_code();

}

/*
    Implementation of the MMGame interface API.
*/
class OnePlayerGame implements MMGame {

    public $pegs = array(BLACK, YELLOW, GREEN, BLUE, PURPLE, WHITE, BLACK);

    private $current_guess;
    private $current_response;
    private $status = 'NEW';
    private $_plays = 0; // accumulator of game turns played.
    private $_max_plays = 12;
    private $_code_generator;
    private $_peg_guess_size = 5; // ie 5 pegs per guess.

    public function __construct() {
        $this->status = 'PLAY';
        $this->_code_generator = new SecretCodeGenerator();
    }


    public function guess($aGuess) {

        if ($this->_validate_guess($aGuess)) {
            $this->status = 'PLAY';

        } else {
            $this->status = 'ERROR';
        }

        if ($this->status == 'PLAY') {
            // $this->_check_guess($aGuess)
            // $this->
        }

        $this->current_response = array('status' => $this->status); // 'response' => $this->peg_response;

        return $this->current_response;
    }


    public function res(){}

    public function status(){
        return $this->status;
    }


    private function _validate_guess($aGuess) {

        $is_valid = false;

        if (is_array($aGuess) and (count($aGuess) == $this->_peg_guess_size) ) {
            $is_valid = true;
        }

        foreach ($aGuess as $peg_guess) {
            
            $is_match = false;

            foreach ($this->pegs as $valid_peg) {
                if ($peg_guess == $valid_peg) {
                    $is_match = true;
                }
            }

            if (!$is_match) {
                $is_valid = false;
                break;
            } 
        }

        return $is_valid;
    }

    public function check_guess($validGuess) {
        // Check guess and create a peg response to return

        // Check against $this->_code_generator->get_code();

        // set status to 'WIN' if all response pegs are red.
    }

}


/*
    Create and return a secret code.
*/
class SecretCodeGenerator implements CodeGenerator {

    private $_code;

    public function generate() {}

    public function get_code() {}

}


/*
   Create and return a secret code.  Each call to get_code generates a new secret code
   that validates against all past seen guesses.
*/
class CheaterCodeGenerator implements CodeGenerator {

    private $_code;

    public function generate() {}

    public function get_code() {}

}


?>