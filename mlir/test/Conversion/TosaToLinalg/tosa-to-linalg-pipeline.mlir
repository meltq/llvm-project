// RUN: mlir-opt %s --split-input-file --tosa-to-linalg-pipeline -verify-diagnostics


// -----

// check that -tosa-validate of stateful ops kick in
func.func @test_variable_write_shape(%arg0: tensor<1x4x8xi8>) -> () {
  tosa.variable @stored_var = dense<-1> : tensor<2x4x8xi8>
  // expected-error@+1 {{'tosa.variable_write' op operand type does not equal variable type}}
  tosa.variable_write @stored_var, %arg0 : tensor<1x4x8xi8>
  return
}

// -----

// check that -tosa-validate level checking kick in
func.func @tensor_with_unknown_rank(%arg0: tensor<*xi32>) -> tensor<*xi32> {
  // expected-error@+1 {{'tosa.abs' op failed level check: unranked tensor}}
  %0 = "tosa.abs"(%arg0) : (tensor<*xi32>) -> tensor<*xi32>
  return %0 : tensor<*xi32>
}

// -----

// check that tosa verify kick in
func.func @test_avg_pool2d_zero_dim_input(%arg0: tensor<1x0x?x9xf32>, %arg1: tensor<1xf32>, %arg2: tensor<1xf32>) -> tensor<1x7x7x9xf32> {
  // expected-error@+1 {{'tosa.avg_pool2d' op operand #0 must be 4-d tosa-conformant tensor, but got 'tensor<1x0x?x9xf32>'}}
    %0 = "tosa.avg_pool2d"(%arg0, %arg1, %arg2) {acc_type = f32, kernel = array<i64: 2, 2>, pad = array<i64: 0, 1, 0, 1>, stride = array<i64: 1, 1>}
      : (tensor<1x0x?x9xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<1x7x7x9xf32>
    return %0 : tensor<1x7x7x9xf32>
}

// -----

// check that --tosa-to-linalg kick in
func.func @avg_pool2d_with_unsupported_quant_type(%arg0: tensor<1x7x7x9x!quant.uniform<i8:f32, 0.01>>, %arg1: tensor<1xi8>, %arg2: tensor<1xi8>) -> tensor<1x7x7x9x!quant.uniform<i8:f32, 0.01>> {
  // expected-error@+1 {{failed to legalize operation 'tosa.avg_pool2d'}}
  %0 = "tosa.avg_pool2d"(%arg0, %arg1, %arg2) {acc_type = i32, kernel = array<i64: 2, 2>, pad = array<i64: 0, 1, 0, 1>, stride = array<i64: 1, 1>} : (tensor<1x7x7x9x!quant.uniform<i8:f32, 0.01>>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x7x7x9x!quant.uniform<i8:f32, 0.01>>
  return %0 : tensor<1x7x7x9x!quant.uniform<i8:f32, 0.01>>
}
