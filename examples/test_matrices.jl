# Matrices from "A Collection of Test Matrices for Testing Computational Algortihms" 
#   by R.T. Gregory and David L. Karney.  Wiley and Sons.

# Example 3.4 (p. 30).  
# Reference: Wilkinson, J.H. "Error Analysis of Direct Methods of Matrix Inversion." 
#   J. ACM 8, 281-330 (1961).


A = 
  [ 
     1  0  0  0 0  1;
     1  1  0  0 0 -1;
    -1  1  1  0 0  1;
     1 -1  1  1 0 -1;
    -1  1 -1  1 1  1;
     1 -1  1 -1 1 -1
  ]

  Ai = 
  [
    2.0^-1  2^-2   -2^-3    2^-4    -2^-5     2^-5;
    0       2.0^-1  2.0^-2 -2.0^-3  2.0^-4   -2.0^-4;
    0       0       2.0^-1  2.0^-2 -2.0^-3    2.0^-3;
    0       0       0       2.0^-1  2.0^-2   -2.0^-2;
    0       0       0       0       2.0^-1    2.0^-1;
    2^-1   -2^-2    2^-3   -2^-4    2^-5     -2^-5
   ]

   A*Ai
  



# Example 3.5 (p.31)
# References:
# Fox, L.  "A Short Account of Relaxation Methods."  Quart. Jour. Methods of Math. (1948).
# Marcus, M. "Basic Theorems in Matrix Theory." Nat. Bur. Stand. Appl. Math. Series 57, 1-20 (1960)

A = [
  5 7 6 5;
  7 10 8 7;
  6 8 10 9;
  5 7 9 10
]

Ai = 
[
   68 -41 -17 10;
  -41  25  10 -6;
  -17  10   5 -3;
   10 -6   -3  2
]
A*Ai
