use encoder::Encoder;

fn main() {
    let mut enc = Encoder::new(1024);
    let counts_per_rev = 1024;

    println!("Simulating encoder at 50Hz for 2 seconds");
    println!("{:<6} {:<8} {:<12} {:<14}",
        "tick", "count", "pos_rad", "vel_rad_per_s");

    for tick in 0..100 {
        let speed = (tick as f32 * 0.1).sin() * 10.0;
        let delta = speed as i32;

        enc.update(delta, 20.0);

        if tick % 10 == 0 {
            println!("{:<6} {:<8} {:<12.3} {:<14.3}",
                tick,
                enc.count(),
                enc.position_rad(),
                enc.velocity_rad_per_sec()
            );
        }
    }
}