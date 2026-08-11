///|
test "vlq fixture corpus roundtrips every value" {
  let values = @sourcemap.vlq_fixture_values()
  @test.assert_eq(values.length(), 701)
  @test.assert_eq(@sourcemap.vlq_fixture_checksum(), 0)
  for value in values {
    let encoded = @sourcemap.encode_vlq(value)
    @test.assert_eq(
      @sourcemap.decode_vlq(encoded, 0),
      Ok((value, encoded.length())),
    )
  }
}

///|
test "vlq fixture corpus preserves sorted dense window" {
  let values = @sourcemap.vlq_fixture_values()
  for i in 1..<values.length() {
    @test.assert_eq(values[i] - values[i - 1], 1)
  }
}
