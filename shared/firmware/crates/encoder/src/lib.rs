//! Quadrature encoder reader.
//! On real hardware this reads from GPIO interrupt counters.
//! This module simulates the logic for desktop testing.

#![cfg_attr(not(feature = "std"), no_std)]

pub struct Encoder {
    count: i32,
    velocity_counts_per_sec: f32,
    counts_per_rev: i32,
}

impl Encoder {
    pub fn new(counts_per_rev: i32) -> Self {
        Self {
            count: 0,
            velocity_counts_per_sec: 0.0,
            counts_per_rev,
        }
    }

    pub fn update(&mut self, delta: i32, dt_ms:f32) {
        self.count = self.count.saturating_add(delta);
        self.velocity_counts_per_sec = (delta as f32) / (dt_ms / 1000.0);
    }

    pub fn position_rad(&self) -> f32 {
        (self.count as f32 / self.counts_per_rev as f32)
            * 2.0
            * core::f32::consts::PI
    }

    pub fn velocity_rad_per_sec(&self) -> f32 {
        (self.velocity_counts_per_sec / self.counts_per_rev as f32)
            * 2.0
            * core::f32::consts::PI
    }

    pub fn count(&self) -> i32 {
        self.count
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_full_revolution(){
        let mut enc = Encoder::new(1024);
        enc.update(1024, 1000.0);
        let pos = enc.position_rad();

        assert!((pos - 2.0 * core::f32::consts::PI).abs() < 1e-5,
                    "Expected 2π, got {}", pos);
    }

    #[test]
    fn test_velocity(){
        let mut enc = Encoder::new(1024);
        enc.update(1024, 1000.0);
        let vel = enc.velocity_rad_per_sec();

        assert!((vel - 2.0 * core::f32::consts::PI).abs() < 1e-5,
                    "Expected 2π rad/s, got {}", vel);
    }

    #[test]
    fn test_saturation(){
        let mut enc = Encoder::new(1024);
        enc.update(i32::MAX, 20.0);
        enc.update(1, 20.0);
        let count = enc.count();
        assert_eq!(count, i32::MAX, "Count should be saturated at max value");
    }
}
