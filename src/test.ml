func int main(){
  int[] a;
  int[] b;
  a = [1, 2, 3];
  b = [4, 5, 6];
  c = a $ b;
  print(c);

}


int main(){
  int * a; // point to length first, then elements of array 
  int * b;
  a = (int *) malloc(sizeof(int) * 3);
  a[0] = 1;
  a[1] = 2;
  a[2] = 3;
  b = (int *) malloc(sizeof(int) * 3);
  b[0] = 4;
  b[1] = 5;
  b[2] = 6;
  c = array_cat_int(a, b);



}

// pass in length of array and payload for each array 
int * array_cat_int(int * a, int * b){
  result = (int *) malloc(sizeof(int) * (a_len + b_len))
  // copy a into result
  // copy b
  return result;
}